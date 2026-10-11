import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/primary_button.dart';

// Order kamyab! Animation + order id + aage ke buttons.
class OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const OrderSuccessScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/animations/order_success.json',
                height: 200,
                repeat: false,
              ),
              const SizedBox(height: 16),
              Text('Order placed!', style: AppTextStyles.heading),
              const SizedBox(height: 8),
              Text(
                'Your order has been received.\nWe will deliver it soon.',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Order ID: ${orderId.substring(0, 8).toUpperCase()}',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.textWhite),
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                text: 'Track Order',
                onPressed: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.orderDetail,
                  arguments: orderId,
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.main,
                  (_) => false,
                ),
                child: Text(
                  'Continue Shopping',
                  style: AppTextStyles.body
                      .copyWith(color: AppColors.primaryViolet),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
