import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/app_notification.dart';

// Meri notifications: bell badge + notification center ke liye.
class NotificationProvider extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  String? _uid;

  // Login/logout par main.dart se naya uid aata hai (ProxyProvider).
  void setUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    notifyListeners();
  }

  // Meri saari notifications, nayi pehle.
  // (where + Dart sort — composite index ki zaroorat nahi.)
  Stream<List<AppNotification>> notificationsStream() {
    if (_uid == null) return const Stream.empty();
    return _db
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((s) {
      final list =
          s.docs.map((d) => AppNotification.fromMap(d.data(), d.id)).toList();
      list.sort((a, b) {
        final at = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bt = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bt.compareTo(at);
      });
      return list;
    });
  }

  // Unread count (bell badge ke liye)
  Stream<int> unreadCountStream() {
    return notificationsStream()
        .map((list) => list.where((n) => !n.isRead).length);
  }

  // Ek notification parhi hui mark karo
  Future<void> markAsRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  // Saari parhi hui mark karo
  Future<void> markAllAsRead() async {
    if (_uid == null) return;
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // Ek notification delete karo
  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }

  // Saari notifications saaf karo
  Future<void> clearAll() async {
    if (_uid == null) return;
    final snap = await _db
        .collection('notifications')
        .where('userId', isEqualTo: _uid)
        .get();
    final batch = _db.batch();
    for (final d in snap.docs) {
      batch.delete(d.reference);
    }
    await batch.commit();
  }
}
