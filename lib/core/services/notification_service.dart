import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../routes/app_routes.dart';

// Push notifications: FCM + local notifications + tap navigation.
// Flow:
// 1) FCM message aaye (Cloud Function se) -> system tray notification dikhao.
// 2) Notification par tap -> seedha us chat / order par jao.
// 3) In-app notification center ke liye 'notifications' collection me doc banao.
class NotificationService {
  NotificationService._();

  // Navigation ke liye (MaterialApp ka key)
  static final navKey = GlobalKey<NavigatorState>();

  static final _local = FlutterLocalNotificationsPlugin();
  static const _channel = AndroidNotificationChannel(
    'shopnest_high',
    'ShopNest Notifications',
    description: 'Chat messages and order updates',
    importance: Importance.max,
  );

  // App start par ek dafa chalao (main.dart se)
  static Future<void> init() async {
    final messaging = FirebaseMessaging.instance;

    // Local notifications init (Android + iOS)
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) _handlePayload(details.payload!);
      },
    );
    // Android channel banao (warna notification nahi dikhegi)
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Notification ki permission mango (iOS + Android 13+ par zaroori)
    await messaging.requestPermission();
    await saveToken();

    // App khuli ho aur message aaye -> local notification dikhao
    FirebaseMessaging.onMessage.listen((message) {
      _showLocal(
        title: message.notification?.title ?? 'ShopNest',
        body: message.notification?.body ?? '',
        payload: message.data.isEmpty ? null : jsonEncode(message.data),
      );
    });

    // Background se notification tap -> us chat/order par jao
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);

    // App band thi aur notification se khuli -> us chat/order par jao
    final initial = await messaging.getInitialMessage();
    if (initial != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _handleMessage(initial));
    }

    // App band thi aur LOCAL notification se khuli (background handler wali)
    final launch = await _local.getNotificationAppLaunchDetails();
    final launchPayload = launch?.notificationResponse?.payload;
    if (launchPayload != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _handlePayload(launchPayload));
    }

    // Token badal jaye to naya save karo
    FirebaseMessaging.instance.onTokenRefresh.listen((_) => saveToken());

    debugPrint('FCM ready');
  }

  // Is device ka token user ke document me save karo,
  // taake Cloud Function isi device par push bhej sake.
  static Future<void> saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return; // login nahi hai to rehne do
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    debugPrint('FCM TOKEN: $token');
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'fcmTokens': FieldValue.arrayUnion([token]),
    }, SetOptions(merge: true));
  }

  // System tray me notification dikhao
  static Future<void> _showLocal({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (body.isEmpty && title.isEmpty) return;
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  // FCM message (tap) -> sahi screen par jao
  static void _handleMessage(RemoteMessage message) {
    final data = message.data;
    if (data.isEmpty) return;
    _goTo(data['type']?.toString() ?? '', data);
  }

  // Local notification (tap) -> sahi screen par jao
  static void _handlePayload(String payload) {
    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _goTo(data['type']?.toString() ?? '', data);
    } catch (_) {
      // Kharab payload — ignore karo
    }
  }

  static void _goTo(String type, Map data) {
    final nav = navKey.currentState;
    if (nav == null) return;
    if (type == 'chat' && data['chatId'] != null) {
      nav.pushNamed(AppRoutes.chatDetail, arguments: data['chatId']);
    } else if (type == 'order' && data['orderId'] != null) {
      nav.pushNamed(AppRoutes.orderDetail, arguments: data['orderId']);
    } else {
      nav.pushNamed(AppRoutes.notifications);
    }
  }

  // In-app notification center ke liye doc banao.
  // (FCM push Cloud Function bhejta hai — ye doc sirf bell + list ke liye.)
  static Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    required String type, // 'chat' | 'order' | 'general'
    String refId = '',
  }) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'refId': refId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('createNotification failed: $e');
    }
  }
}

// App band ho ya background me ho aur FCM message aaye to ye chalti hai.
// Top-level function hona LAZMI hai (kisi class ke andar nahi).
// Background isolate me apna local plugin init karke notification dikhata hai.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  final local = FlutterLocalNotificationsPlugin();
  await local.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  await local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'shopnest_high',
          'ShopNest Notifications',
          description: 'Chat messages and order updates',
          importance: Importance.max,
        ),
      );
  await local.show(
    DateTime.now().millisecondsSinceEpoch ~/ 1000,
    message.notification?.title ?? 'ShopNest',
    message.notification?.body ?? '',
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'shopnest_high',
        'ShopNest Notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    ),
    payload: message.data.isEmpty ? null : jsonEncode(message.data),
  );
}
