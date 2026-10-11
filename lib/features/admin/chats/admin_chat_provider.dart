import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shopnest/models/chat_message.dart';

// Foreground me naye message ka event — banner dikhane ke liye.
class ChatNotificationEvent {
  final String chatId;
  final String title;
  final String senderName;
  final String message;
  ChatNotificationEvent({
    required this.chatId,
    required this.title,
    required this.senderName,
    required this.message,
  });
}

// Admin chat: live list + reply + unread count + foreground notifications.
class AdminChatProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;

  // Saari chat threads, newest first — LIVE.
  Stream<List<ChatThread>> get threadsStream {
    return _db
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatThread.fromMap(d.data(), d.id)).toList());
  }

  // Ek thread ke messages — LIVE, purane se naye ki tarteeb me.
  Stream<List<ChatMessage>> messagesStream(String chatId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList());
  }

  // Har chat ka unread count (is admin ke liye) — LIVE.
  Stream<Map<String, int>> unreadMapStream(String uid) {
    return _db.collection('chats').snapshots().map((snap) {
      final map = <String, int>{};
      for (final d in snap.docs) {
        final counts =
            Map<String, dynamic>.from(d.data()['unreadCounts'] ?? {});
        map[d.id] = ((counts[uid] as num?) ?? 0).toInt();
      }
      return map;
    });
  }

  // Admin ka reply. Batch write: message save + thread update +
  // customer ka unread +1 — sab ek saath, ya kuch nahi.
  Future<String?> sendReply({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final msg = text.trim();
    if (msg.isEmpty) return 'Please type a message';
    try {
      final threadDoc = await _db.collection('chats').doc(chatId).get();
      final parts = List<String>.from(threadDoc.data()?['participants'] ?? []);
      final recipient =
          parts.firstWhere((p) => p != senderId, orElse: () => '');

      final batch = _db.batch();
      final threadRef = _db.collection('chats').doc(chatId);
      final msgRef = threadRef.collection('messages').doc();
      batch.set(msgRef, {
        'senderId': senderId,
        'senderName': senderName,
        'text': msg,
        'imageUrl': '',
        'type': 'text',
        'createdAt': FieldValue.serverTimestamp(),
      });
      final threadUpdate = <String, dynamic>{
        'lastMessage': msg,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastSenderId': senderId,
        'lastSenderName': senderName,
      };
      if (recipient.isNotEmpty) {
        threadUpdate['unreadCounts.$recipient'] = FieldValue.increment(1);
      }
      batch.update(threadRef, threadUpdate);
      await batch.commit();
      return null;
    } catch (e) {
      return 'Failed to send: $e';
    }
  }

  // Thread kholne par apna unread count zero karo.
  Future<void> markAsRead(String chatId, String uid) async {
    try {
      await _db.collection('chats').doc(chatId).update({
        'unreadCounts.$uid': 0,
      });
    } catch (_) {}
  }

  // ---------- Foreground notifications (bina server ke) ----------

  final _seen = <String, DateTime?>{};
  StreamController<ChatNotificationEvent>? _notifController;
  StreamSubscription<QuerySnapshot>? _notifSub;
  bool _notifStarted = false;

  // Jo thread abhi khuli hai — uska banner skip hoga.
  String? openChatId;

  Stream<ChatNotificationEvent> get notificationsStream =>
      _notifController?.stream ?? const Stream.empty();

  // Ek dafa call karo (Chats screen ke initState se).
  void startNotifications(String myUid) {
    if (_notifStarted) return;
    _notifStarted = true;
    _notifController = StreamController<ChatNotificationEvent>.broadcast();
    var firstLoad = true;
    _notifSub = _db
        .collection('chats')
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .listen((snap) {
      for (final d in snap.docs) {
        final data = d.data();
        final at = (data['lastMessageAt'] as Timestamp?)?.toDate();
        final senderId = data['lastSenderId'] as String?;
        final prev = _seen[d.id];
        final isNew = at != null && (prev == null || at.isAfter(prev));
        _seen[d.id] = at;
        if (firstLoad || !isNew) continue;
        if (senderId == null || senderId == myUid) continue;
        if (openChatId == d.id) continue;
        _notifController?.add(ChatNotificationEvent(
          chatId: d.id,
          title: data['productName'] as String? ?? 'New message',
          senderName: data['lastSenderName'] as String? ?? '',
          message: data['lastMessage'] as String? ?? '',
        ));
      }
      firstLoad = false;
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _notifController?.close();
    super.dispose();
  }
}
