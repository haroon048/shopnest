// Poori app ka root widget: theme aur routes yahan se control honge.
import 'package:flutter/material.dart';

import 'core/services/notification_service.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';

class ShopNestApp extends StatelessWidget {
  const ShopNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NotificationService.navKey,
      title: 'ShopNest',
      debugShowCheckedModeBanner: false, // upar wala debug banner hatao
      theme: AppTheme.darkTheme, // Midnight Luxe theme
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
