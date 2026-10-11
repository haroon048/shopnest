// App ka entry point. Yahan Firebase start hota hai aur providers lagte hain.
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shopnest/features/admin/categories/admin_category_provider.dart';
import 'package:shopnest/features/admin/chats/admin_chat_provider.dart';
import 'package:shopnest/features/admin/orders/admin_order_provider.dart';
import 'features/admin/dashboard/dashboard_provider.dart';

import 'app.dart';
import 'features/admin/products/admin_product_provider.dart';

import 'core/services/notification_service.dart';
import 'features/auth/auth_provider.dart';
import 'features/cart/cart_provider.dart';
import 'features/chat/chat_provider.dart';
import 'features/checkout/checkout_provider.dart';
import 'features/home/home_provider.dart';
import 'features/orders/orders_provider.dart';
import 'features/product/product_provider.dart';
import 'features/wishlist/wishlist_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(
    firebaseMessagingBackgroundHandler,
  );
  await NotificationService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardProvider()),

        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => AdminProductProvider()),
        ChangeNotifierProvider(create: (_) => AdminCategoryProvider()),
        ChangeNotifierProvider(create: (_) => AdminOrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminChatProvider()),

        ChangeNotifierProxyProvider<AuthProvider, CheckoutProvider>(
          create: (_) => CheckoutProvider(),
          update: (_, auth, checkout) => checkout!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, OrdersProvider>(
          create: (_) => OrdersProvider(),
          update: (_, auth, orders) => orders!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, chat) => chat!,
        ),
        // Cart/Wishlist ko login user ka uid chahiye hota hai,
        // is liye inhe AuthProvider se jor diya hai.
        // Login/logout par uid khud-ba-khud update ho jata hai.
        ChangeNotifierProxyProvider<AuthProvider, CartProvider>(
          create: (_) => CartProvider(),
          update: (_, auth, cart) => cart!..setUser(auth.user?.uid),
        ),
        ChangeNotifierProxyProvider<AuthProvider, WishlistProvider>(
          create: (_) => WishlistProvider(),
          update: (_, auth, wish) => wish!..setUser(auth.user?.uid),
        ),
      ],
      child: const ShopNestApp(),
    ),
  );
}
