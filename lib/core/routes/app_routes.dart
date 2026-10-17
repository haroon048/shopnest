import 'package:flutter/material.dart';
import 'package:shopnest/features/auth/signup.dart';
import '../../features/auth/role_select_screen.dart';

import '../../features/auth/forgot_password_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/store/create_store_screen.dart';
import '../../features/store/store_dashboard_screen.dart';
import '../../features/store/store_picker_screen.dart';
import '../../features/admin/admin_main_screen.dart';
import '../../features/main/main_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/product/product_detail_screen.dart';
import '../../features/shop/shop_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/checkout/checkout_screen.dart';
import '../../features/checkout/order_success_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/orders/order_detail_screen.dart';
import '../../features/orders/orders_screen.dart';
import '../../features/chat/chat_detail_screen.dart';

// Saare route names ek jagah - spelling mistakes se bachne ke liye.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgot = '/forgot';
  static const String main = '/main';
  static const String shop = '/shop';
  static const String productDetail = '/product';
  static const String adminMain = '/adminMain';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orders = '/orders';
  static const String orderDetail = '/order-detail';
  static const String chatDetail = '/chat-detail';
  static const String roleSelect = '/roleSelect';
  static const String storePicker = '/store-picker';
  static const String createStore = '/create-store';
  static const String storeDashboard = '/store-dashboard';
  static const String notifications = '/notifications';

  // Baaki routes Phase-wise add honge

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case login:
        final role = settings.arguments as String?;
        return MaterialPageRoute(builder: (_) => LoginScreen(role: role));

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());
      case forgot:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
      case main:
        return MaterialPageRoute(builder: (_) => const MainScreen());
      case adminMain:
        return MaterialPageRoute(builder: (_) => const AdminMainScreen());
      case shop:
        final args = settings.arguments as Map<String, String?>?;
        return MaterialPageRoute(
          builder: (_) => ShopScreen(initialCategoryId: args?['categoryId']),
        );
      case productDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(productId: id),
        );
      case wishlist:
        return MaterialPageRoute(builder: (_) => const WishlistScreen());
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen());
      case orderSuccess:
        final orderId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(orderId: orderId),
        );
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case orderDetail:
        final id = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => OrderDetailScreen(orderId: id),
        );
      case chatDetail:
        final chatId = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ChatDetailScreen(chatId: chatId),
        );
      case roleSelect:
        return MaterialPageRoute(builder: (_) => const RoleSelectScreen());
      case storePicker:
        return MaterialPageRoute(builder: (_) => const StorePickerScreen());
      case createStore:
        return MaterialPageRoute(builder: (_) => const CreateStoreScreen());
      case storeDashboard:
        return MaterialPageRoute(builder: (_) => const StoreDashboardScreen());
      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        // Agar route na mile to splash par bhejo
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
