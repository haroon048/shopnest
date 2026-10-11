import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/order.dart';
import 'orders_provider.dart';

// Order ka detail: live status timeline + items + bill.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  // Status ke steps (timeline me)
  static const _steps = ['pending', 'confirmed', 'shipped', 'delivered'];
  static const _labels = ['Pending', 'Confirmed', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    final orders = context.read<OrdersProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Order Detail', style: AppTextStyles.heading),
      ),
      body: StreamBuilder<Order?>(
        stream: orders.orderStream(orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryViolet),
            );
          }
          final order = snap.data;
          if (order == null) {
            return Center(
              child: Text('Order not found.', style: AppTextStyles.body),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status timeline (live)
                order.status == 'cancelled'
                    ? _cancelledBox()
                    : _timeline(order),
                const SizedBox(height: 20),
                Text('Items', style: AppTextStyles.subHeading),
                const SizedBox(height: 8),
                ...order.items.map(_itemTile),
                const SizedBox(height: 20),
                Text('Delivery Address', style: AppTextStyles.subHeading),
                const SizedBox(height: 8),
                _infoBox(
                    '${order.address.name}\n${order.address.full}\n${order.address.phone}'),
                const SizedBox(height: 20),
                Text('Bill', style: AppTextStyles.subHeading),
                const SizedBox(height: 8),
                _infoBox(
                  'Subtotal: Rs ${order.subtotal.toStringAsFixed(0)}\n'
                  'Delivery: ${order.deliveryFee == 0 ? 'FREE' : 'Rs ${order.deliveryFee.toStringAsFixed(0)}'}\n'
                  '${order.discount > 0 ? 'Discount: - Rs ${order.discount.toStringAsFixed(0)}\n' : ''}'
                  'Total: Rs ${order.total.toStringAsFixed(0)}\n'
                  'Payment: Cash on Delivery',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Live status timeline.
  // Console me order ka status badlo, yahan khud update hoga!
  Widget _timeline(Order order) {
    final current = _steps.indexOf(order.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Dots ke beech wali line
            final done = (i ~/ 2) < current;
            return Expanded(
              child: Container(
                height: 2,
                color: done ? AppColors.success : Colors.white10,
              ),
            );
          }
          final stepIndex = i ~/ 2;
          final done = stepIndex <= current && current >= 0;
          return Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? AppColors.success : AppColors.surface2,
                ),
                child: Icon(
                  done ? Icons.check : Icons.circle,
                  size: 14,
                  color: done ? Colors.white : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _labels[stepIndex],
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _cancelledBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'This order has been cancelled.',
        style: AppTextStyles.body.copyWith(color: AppColors.accent),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _itemTile(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.image,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Image.asset(
                'assets/images/placeholders/placeholder_product.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name,
                    style: AppTextStyles.body,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(
                  '${item.qty} x Rs ${item.price.toStringAsFixed(0)}',
                  style: AppTextStyles.caption,
                ),
              ],
            ),
          ),
          Text(
            'Rs ${(item.price * item.qty).toStringAsFixed(0)}',
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(height: 1.6),
      ),
    );
  }
}
