import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../models/order.dart';
import 'admin_order_provider.dart';
import 'order_detail_screen.dart';

/// All orders, newest first, with status filter chips.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  String? _filter; // null = All

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
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0B14),
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _filterChips(),
          Expanded(
            child: StreamBuilder<List<Order>>(
              stream: context.read<AdminOrderProvider>().ordersStream,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Text('Something went wrong: ${snap.error}',
                        style: const TextStyle(color: Colors.white54)),
                  );
                }
                var orders = snap.data ?? [];
                // Client-side filter (avoids composite index setup)
                if (_filter != null) {
                  orders = orders.where((o) => o.status == _filter).toList();
                }
                if (orders.isEmpty) {
                  return const Center(
                    child: Text('No orders found.',
                        style: TextStyle(color: Colors.white54)),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, i) => _orderCard(context, orders[i])
                      .animate()
                      .fadeIn(delay: (60 * i).ms)
                      .slideY(begin: 0.15, end: 0),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChips() {
    final options = <String?>[null, ...OrderStatuses.all];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: options.length,
        itemBuilder: (context, i) {
          final s = options[i];
          final selected = _filter == s;
          return ChoiceChip(
            label: Text(s == null ? 'All' : _label(s)),
            selected: selected,
            onSelected: (_) => setState(() => _filter = s),
            selectedColor: const Color(0xFF8B5CF6),
            backgroundColor: Colors.white.withValues(alpha: 0.06),
            labelStyle:
                TextStyle(color: selected ? Colors.white : Colors.white70),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          );
        },
      ),
    );
  }

  Widget _orderCard(BuildContext context, Order order) {
    final color = _statusColor(order.status);
    final shortId = order.id.length > 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            // Pending orders glow orange so they catch the eye
            color: order.status == OrderStatuses.pending
                ? Colors.orange.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('#$shortId',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15)),
                _statusBadge(order.status, color),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${order.items.length} items',
                    style: const TextStyle(color: Colors.white54)),
                Text('Rs ${order.total}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
              ],
            ),
            const SizedBox(height: 4),
            Text(_date(order.createdAt),
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35), fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(_label(status),
          style: TextStyle(
              color: color, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
