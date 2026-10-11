import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

// Push notifications: permission, token save, foreground/background handle.
class NotificationService {
  NotificationService._();

  // Foreground banner dikhane ke liye (MaterialApp ka key)
  static final navKey = GlobalKey<NavigatorState>();

  // App start par ek dafa chalao (main.dart se)
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Notification ki permission mango (iOS + Android 13+ par zaroori)
    await messaging.requestPermission();
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('FCM TOKEN: $token');
    }

    // App khuli ho aur message aaye to chhota banner dikhao
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Token badal jaye to naya save karo
    FirebaseMessaging.instance.onTokenRefresh.listen(
      (_) => saveToken(),
    );

    debugPrint('FCM ready');
  }

  // Is device ka token user ke document me save karo,
  // taake baad me isi device par push bheja ja sake.
  static Future<void> saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // login nahi hai to rehne do
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    // Test ke liye: debug console se token copy kar lena
    debugPrint('FCM TOKEN: $token');
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  // App khuli ho to message ka chhota banner
  static void _showForeground(RemoteMessage message) {
    final context = navKey.currentContext;
    if (context == null) return;
    final title = message.notification?.title ?? 'ShopNest';
    final body = message.notification?.body ?? '';
    if (body.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$title: $body'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// App band ho ya background me ho aur message aaye to ye chalti hai.
// Top-level function hona LAZMI hai (kisi class ke andar nahi).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background notification: ${message.notification?.title}');
}
