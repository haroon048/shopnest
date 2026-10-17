import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/chat_message.dart'; // ChatThread + ChatMessage yahan se

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
  Stream<List<ChatThread>> chatsStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('chats')
        .where('participants', arrayContains: uid)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => ChatThread.fromMap(d.data(), d.id)).toList();
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

  // ---------- Ek chat ke messages (naye sab se upar) ----------
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList());
  }

  // ---------- Chat dhundo, na mile to nayi banao ----------
  // storeId: chat kis store ki hai (product detail se product.storeId bhejo).
  Future<String> getOrCreateChat({
    required String productId,
    required String productName,
    required String productImage,
    required String sellerId,
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
      'storeId': storeId, // chat kis store ki hai
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'lastMessage': '',
      'lastSenderId': '',
      'lastSenderName': '',
      'lastMessageAt': FieldValue.serverTimestamp(),
      'unreadCounts': {uid: 0, sellerId: 0},
    });
    return ref.id;
  }

  // ---------- Message bhejo (text ya photo) ----------
  // Kamyabi par null, nakami par error ka text wapas
  Future<String?> sendMessage({
    required String chatId,
    String? text,
    XFile? imageFile,
  }) async {
    try {
      if (imageFile != null) {
        final url = await _uploadToCloudinary(File(imageFile.path));
        await _sendMessage(
            chatId: chatId, text: '', imageUrl: url, type: 'image');
      } else {
        await _sendMessage(
            chatId: chatId, text: text ?? '', imageUrl: '', type: 'text');
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
      'createdAt': FieldValue.serverTimestamp(),
    });
    final updates = <String, dynamic>{
      'lastMessage': type == 'image' ? 'Photo' : text,
      'lastSenderId': uid,
      'lastSenderName': name,
      'lastMessageAt': FieldValue.serverTimestamp(),
    };
    if (other.isNotEmpty) {
      updates['unreadCounts.$other'] = FieldValue.increment(1);
    }
    batch.update(chatRef, updates);
    await batch.commit();
  }

  // ---------- Chat kholne par unread zero ----------
  Future<void> markAsRead(String chatId, String uid) async {
    await _db.collection('chats').doc(chatId).update({'unreadCounts.$uid': 0});
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
