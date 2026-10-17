import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/chat_message.dart'; // ChatThread + ChatMessage yahan se
import '../../core/services/notification_service.dart';

// Upar se girne wale banner ka event
class ChatNotificationEvent {
  final String chatId;
  final String senderName;
  final String title; // sender naam na ho to product ka naam
  final String message;

  ChatNotificationEvent({
    required this.chatId,
    required this.senderName,
    required this.title,
    required this.message,
  });
}

class ChatProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Cloudinary — tasveer upload ke liye
  static const _cloudName = 'kdgf3mee';
  static const _preset = 'shopnest_unsigned';

  // Kaunsi chat is waqt khuli hai (us par banner nahi dikhana)
  String? openChatId;

  final _notifCtrl = StreamController<ChatNotificationEvent>.broadcast();
  Stream<ChatNotificationEvent> get notificationsStream => _notifCtrl.stream;

  bool _notifStarted = false;
  bool _firstSnap = true;
  StreamSubscription? _chatsSub;

  // ---------- Chat list ----------
  // NOTE: sirf arrayContains — isme composite index NAHI chahiye.
  // Sorting (naye pehle) Dart me hoti hai, Firestore me orderBy nahi.
  // Apne liye delete ki hui chats nahi dikhengi.
  Stream<List<ChatThread>> chatsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      var list = s.docs.map((d) => ChatThread.fromMap(d.data(), d.id)).toList();
      // Apne liye delete ki hui chats chhupao
      list = list.where((t) => !t.deletedFor.contains(uid)).toList();
      // Null-safe sorting: jiska time nahi, wo sab se neeche
      list.sort((a, b) {
        final at = a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  // ---------- Har chat ke unread count (badge ke liye) ----------
  Stream<Map<String, int>> unreadMapStream(String uid) {
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      final map = <String, int>{};
      for (final d in s.docs) {
        final raw = d.data()['unreadCounts'];
        int count = 0;
        if (raw is Map && raw[uid] is num) {
          count = (raw[uid] as num).toInt();
        }
        map[d.id] = count;
      }
      return map;
    });
  }

  // ---------- Ek thread ka live document (app bar ke liye) ----------
  Stream<DocumentSnapshot<Map<String, dynamic>>> threadStream(String chatId) {
    return _db.collection('chats').doc(chatId).snapshots();
  }

  // ---------- Ek thread ek dafa parho (buyer/product maloom karne ke liye) ----------
  Future<ChatThread?> getThread(String chatId) async {
    final d = await _db.collection('chats').doc(chatId).get();
    if (!d.exists || d.data() == null) return null;
    return ChatThread.fromMap(d.data()!, d.id);
  }

  // ---------- Kaun typing kar raha hai (uid, khaali = koi nahi) ----------
  Stream<String> typingStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((d) => d.data()?['typingBy'] as String? ?? '');
  }

  // ---------- Ek chat ke messages (naye sab se upar) ----------
  // Apne liye delete kiye hue messages nahi dikhenge.
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    final uid = _auth.currentUser?.uid ?? '';
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => ChatMessage.fromMap(d.data(), d.id))
            .where((m) => !m.deletedFor.contains(uid))
            .toList());
  }

  // ---------- Chat dhundo, na mile to nayi banao ----------
  Future<String> getOrCreateChat({
    required String productId,
    required String productName,
    required String productImage,
    required String sellerId,
    // storeId: chat kis store ki hai (product detail se product.storeId bhejo).
    String storeId = '',
  }) async {
    final user = _auth.currentUser!;
    final uid = user.uid;
    final name = user.displayName ?? 'Customer';

    // Meri chats me se isi product wali dhundo (Dart me filter — index nahi chahiye)
    final snap = await _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();
    for (final d in snap.docs) {
      if (d.data()['productId']?.toString() == productId) return d.id;
    }

    // Nayi chat banao
    final ref = _db.collection('chats').doc();
    await ref.set({
      'participants': [uid, sellerId],
      'buyerId': uid, // purane structure se match karne ke liye
      'customerId': uid,
      'customerName': name,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'storeId': storeId, // chat kis store ki hai
      'lastMessage': '',
      'lastSenderId': '',
      'lastSenderName': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageStatus': 'sent',
      'typingBy': '',
      'deletedFor': [],
      'unreadCounts': {uid: 0, sellerId: 0},
    });
    return ref.id;
  }

  // ---------- Message bhejo (text ya photo, reply ke saath) ----------
  // Kamyabi par null, nakami par error ka text wapas
  Future<String?> sendMessage({
    required String chatId,
    String? text,
    XFile? imageFile,
    ChatMessage? replyTo,
  }) async {
    try {
      if (imageFile != null) {
        final url = await _uploadToCloudinary(File(imageFile.path));
        await _sendMessage(
          chatId: chatId,
          text: '',
          imageUrl: url,
          type: 'image',
          replyTo: replyTo,
        );
      } else {
        await _sendMessage(
          chatId: chatId,
          text: text ?? '',
          imageUrl: '',
          type: 'text',
          replyTo: replyTo,
        );
      }
      return null;
    } catch (e) {
      return 'Could not send the message. Please try again.';
    }
  }

  Future<void> _sendMessage({
    required String chatId,
    required String text,
    required String imageUrl,
    required String type,
    ChatMessage? replyTo,
  }) async {
    final user = _auth.currentUser!;
    final uid = user.uid;
    final name = user.displayName ?? 'Customer';
    final chatRef = _db.collection('chats').doc(chatId);

    // Saamne wale ka uid nikalo taake uska unread +1 ho
    String other = '';
    final chatSnap = await chatRef.get();
    final parts = chatSnap.data()?['participants'];
    if (parts is List) {
      for (final p in parts) {
        if (p.toString() != uid) other = p.toString();
      }
    }

    // Ek batch me: message save + thread update + unread +1
    final batch = _db.batch();
    batch.set(chatRef.collection('messages').doc(), {
      'senderId': uid,
      'senderName': name,
      'text': text,
      'imageUrl': imageUrl,
      'type': type,
      'status': 'sent',
      'deletedFor': [],
      'deletedForEveryone': false,
      'replyToId': replyTo?.id ?? '',
      'replyToText':
          replyTo != null ? (replyTo.isImage ? 'Photo' : replyTo.text) : '',
      'replyToName': replyTo?.senderName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    final updates = <String, dynamic>{
      'lastMessage': type == 'image' ? 'Photo' : text,
      'lastSenderId': uid,
      'lastSenderName': name,
      'lastMessageAt': FieldValue.serverTimestamp(),
      'lastMessageStatus': 'sent',
    };
    if (other.isNotEmpty) {
      updates['unreadCounts.$other'] = FieldValue.increment(1);
    }
    batch.update(chatRef, updates);
    await batch.commit();

    // Saamne wale ke liye notification doc (bell + center ke liye).
    // FCM push Cloud Function bhejta hai — ye doc sirf in-app list ke liye hai.
    if (other.isNotEmpty) {
      await NotificationService.createNotification(
        userId: other,
        title: name,
        body: type == 'image' ? 'Sent a photo' : text,
        type: 'chat',
        refId: chatId,
      );
    }
  }

  // ---------- Chat kholne par: messages "delivered" se "seen" ----------
  // + unread zero + thread status seen.
  Future<void> markAsSeen(String chatId, String uid) async {
    await markAsRead(chatId, uid);
    final snap = await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .get();
    final batch = _db.batch();
    var changed = false;
    for (final d in snap.docs) {
      final m = d.data();
      if (m['senderId'] != uid && m['status'] != 'seen') {
        batch.update(d.reference, {'status': 'seen'});
        changed = true;
      }
    }
    if (changed) {
      batch.update(
        _db.collection('chats').doc(chatId),
        {'lastMessageStatus': 'seen'},
      );
      await batch.commit();
    }
  }

  // ---------- Chat list kholne par: saare threads "delivered" ----------
  // (Sirf thread ka status — message docs detail screen me seen hote hain.)
  Future<void> markAllDelivered(String uid) async {
    final snap = await _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .get();
    final batch = _db.batch();
    var changed = false;
    for (final d in snap.docs) {
      final data = d.data();
      if (data['lastSenderId'] != uid && data['lastMessageStatus'] == 'sent') {
        batch.update(d.reference, {'lastMessageStatus': 'delivered'});
        changed = true;
      }
    }
    if (changed) await batch.commit();
  }

  // ---------- Chat kholne par unread zero ----------
  Future<void> markAsRead(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({'unreadCounts.$uid': 0});
  }

  // ---------- Typing indicator ----------
  Future<void> setTyping(String chatId, bool isTyping) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('chats').doc(chatId).update({
      'typingBy': isTyping ? uid : '',
    });
  }

  // ---------- Ek message apne liye delete karo ----------
  Future<void> deleteMessageForMe(String chatId, String messageId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  // ---------- Ek message sab ke liye delete karo (sirf apna message) ----------
  Future<void> deleteMessageForEveryone(String chatId, String messageId) async {
    await _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedForEveryone': true,
      'text': '',
      'imageUrl': '',
    });
  }

  // ---------- Poori chat apne liye saaf karo ----------
  Future<void> clearChat(String chatId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final snap =
        await _db.collection('chats').doc(chatId).collection('messages').get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {
        'deletedFor': FieldValue.arrayUnion([uid]),
      });
    }
    await batch.commit();
  }

  // ---------- Chat apni list se delete karo (doosre ko rehti hai) ----------
  Future<void> deleteChatForMe(String chatId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('chats').doc(chatId).update({
      'deletedFor': FieldValue.arrayUnion([uid]),
    });
  }

  // ---------- Cloudinary par tasveer ----------
  Future<String> _uploadToCloudinary(File file) async {
    final uri =
        Uri.parse('https://api.cloudinary.com/v1_1/$_cloudName/image/upload');
    final req = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _preset
      ..files.add(await http.MultipartFile.fromPath('file', file.path));
    final res = await req.send();
    final body = await res.stream.bytesToString();
    if (res.statusCode == 200) {
      return (jsonDecode(body)['secure_url'] as String?) ?? '';
    }
    throw Exception('Image upload failed (${res.statusCode})');
  }

  // ---------- Foreground notifications (app khuli ho to banner) ----------
  void startNotifications(String uid) {
    if (_notifStarted) return;
    _notifStarted = true;
    _chatsSub = _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snap) {
      for (final c in snap.docChanges) {
        if (_firstSnap) continue; // pehli load par banner nahi
        if (c.type == DocumentChangeType.removed) continue;
        final d = c.doc.data();
        if (d == null) continue;
        final senderId = d['lastSenderId']?.toString() ?? '';
        if (senderId.isEmpty || senderId == uid) continue; // apna message nahi
        if (c.doc.id == openChatId) continue; // khuli chat par nahi
        // Sirf taaza message (2 min ke andar) par banner
        final ts = d['lastMessageAt'];
        if (ts is Timestamp &&
            DateTime.now().difference(ts.toDate()).inMinutes > 2) {
          continue;
        }
        _notifCtrl.add(ChatNotificationEvent(
          chatId: c.doc.id,
          senderName: d['lastSenderName']?.toString() ?? '',
          title: d['productName']?.toString() ?? 'New message',
          message: d['lastMessage']?.toString() ?? '',
        ));
      }
      _firstSnap = false;
    });
  }

  @override
  void dispose() {
    _chatsSub?.cancel();
    _notifCtrl.close();
    super.dispose();
  }
}
