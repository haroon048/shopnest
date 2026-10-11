import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/order.dart';
import 'admin_order_provider.dart';

/// Order detail: live status pills, customer/address, items, totals.
/// NOTE: Address ke field names (name, phone, address, city) apne
/// address.dart se match karo — agar naam aur hain to badal lena.
class OrderDetailScreen extends StatelessWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  Color _statusColor(String s) {
    switch (s) {
      case OrderStatuses.pending:
        return Colors.orange;
      case OrderStatuses.confirmed:
        return Colors.blue;
      case OrderStatuses.shipped:
        return const Color(0xFF8B5CF6);
      case OrderStatuses.delivered:
        return Colors.green;
      case OrderStatuses.cancelled:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _label(String s) {
    switch (s) {
      case OrderStatuses.confirmed:
        return 'Confirmed';
      case OrderStatuses.shipped:
        return 'Shipped';
      case OrderStatuses.delivered:
        return 'Delivered';
      case OrderStatuses.cancelled:
        return 'Cancelled';
      default:
        return 'Pending';
    }
  }

  String _date(DateTime? dt) {
    if (dt == null) return '—';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _changeStatus(BuildContext context, String s) async {
    final error =
        await context.read<AdminOrderProvider>().updateStatus(orderId, s);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ?? 'Order marked as ${_label(s)}'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<Order?>(
        stream: context.read<AdminOrderProvider>().orderStream(orderId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData || snap.data == null) {
            return const Center(
                child: Text('Could not load order.',
                    style: TextStyle(color: Colors.white54)));
          }
          final order = snap.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Update Status'),
                _statusPills(context, order.status),
                const SizedBox(height: 20),
                _sectionTitle('Customer'),
                _infoCard([
                  _row('Name', order.address.name),
                  _row('Phone', order.address.phone),
                  _row('Address', order.address.full),
                ]),
                const SizedBox(height: 20),
                _sectionTitle('Items (${order.items.length})'),
                ...order.items.map((it) => _itemRow(it)),
                const SizedBox(height: 20),
                _sectionTitle('Summary'),
                _infoCard([
                  _row('Subtotal', 'Rs ${order.subtotal}'),
                  _row('Delivery', 'Rs ${order.deliveryFee}'),
                  if (order.discount > 0)
                    _row('Discount', '- Rs ${order.discount}'),
                  _row('Payment', order.paymentMethod.toUpperCase()),
                  _row('Order date', _date(order.createdAt)),
                  _row('Total', 'Rs ${order.total}', bold: true),
                ]),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tappable status pills — the active one glows.
  Widget _statusPills(BuildContext context, String current) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: OrderStatuses.all.map((s) {
        final active = s == current;
        final color = _statusColor(s);
        return GestureDetector(
          onTap: active ? null : () => _changeStatus(context, s),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: active
                  ? LinearGradient(
                      colors: [color, color.withValues(alpha: 0.7)])
                  : null,
              color: active ? null : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                  color: color.withValues(alpha: active ? 0.8 : 0.3)),
              boxShadow: active
                  ? [
                      BoxShadow(
                          color: color.withValues(alpha: 0.4), blurRadius: 12)
                    ]
                  : null,
            ),
            child: Text(_label(s),
                style: TextStyle(
                    color: active ? Colors.white : color,
                    fontWeight: FontWeight.w600)),
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      );

  Widget _infoCard(List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(children: children),
      );

  Widget _row(String k, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(color: Colors.white54)),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
            ),
          ],
        ),
      );

  Widget _itemRow(OrderItem it) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text('${it.name}  × ${it.qty}',
                  style: const TextStyle(color: Colors.white)),
            ),
            Text('Rs ${it.price * it.qty}',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
