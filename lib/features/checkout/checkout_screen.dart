import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/routes/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/glowing_textfield.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/address.dart';
import '../cart/cart_provider.dart';
import 'checkout_provider.dart';

// Checkout: address chunna, payment method, order summary, order place karna.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final checkout = context.watch<CheckoutProvider>();
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Checkout', style: AppTextStyles.heading),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivery Address', style: AppTextStyles.subHeading),
                  const SizedBox(height: 8),
                  _addressSection(context, checkout),
                  const SizedBox(height: 20),
                  Text('Payment Method', style: AppTextStyles.subHeading),
                  const SizedBox(height: 8),
                  _paymentSection(),
                  const SizedBox(height: 20),
                  Text('Order Summary', style: AppTextStyles.subHeading),
                  const SizedBox(height: 8),
                  _summarySection(cart),
                ],
              ),
            ),
          ),
          _bottomBar(context, checkout, cart),
        ],
      ),
    );
  }

  // Address list + naya address add karne ka button
  Widget _addressSection(BuildContext context, CheckoutProvider checkout) {
    if (checkout.addresses.isEmpty) {
      return _addAddressButton(context, fullWidth: true);
    }
    return Column(
      children: [
        ...checkout.addresses.map((a) => _addressTile(context, checkout, a)),
        const SizedBox(height: 8),
        _addAddressButton(context),
      ],
    );
  }

  Widget _addressTile(
      BuildContext context, CheckoutProvider checkout, Address a) {
    final selected = checkout.selectedAddress?.id == a.id;
    return GestureDetector(
      onTap: () => checkout.selectAddress(a),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.primaryViolet
                : Colors.white.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primaryViolet : AppColors.textMuted,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(a.label,
                          style: AppTextStyles.body
                              .copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(a.name, style: AppTextStyles.caption),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(a.full,
                      style: AppTextStyles.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  Text(a.phone, style: AppTextStyles.caption),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20),
              color: AppColors.textMuted,
              onPressed: () => checkout.deleteAddress(a.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addAddressButton(BuildContext context, {bool fullWidth = false}) {
    return SizedBox(
      width: fullWidth ? double.infinity : null,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add New Address'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryViolet,
          side: const BorderSide(color: AppColors.primaryViolet),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        onPressed: () => _showAddressSheet(context),
      ),
    );
  }

  // Neeche se khulne wala address form
  void _showAddressSheet(BuildContext context) {
    final checkout = context.read<CheckoutProvider>();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final streetCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String label = 'Home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 20,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('New Address', style: AppTextStyles.subHeading),
                  const SizedBox(height: 16),
                  // Label chunna: Home / Office
                  Row(
                    children: ['Home', 'Office'].map((l) {
                      final sel = label == l;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(l),
                          selected: sel,
                          onSelected: (_) => setSheetState(() => label = l),
                          selectedColor: AppColors.primaryViolet,
                          backgroundColor: AppColors.surface2,
                          labelStyle: AppTextStyles.caption.copyWith(
                            color: sel ? Colors.white : AppColors.textMuted,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  GlowingTextField(
                    hint: 'Full name',
                    controller: nameCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your name.' : null,
                  ),
                  const SizedBox(height: 12),
                  GlowingTextField(
                    hint: 'Phone (03XXXXXXXXX)',
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Enter your phone number.';
                      }
                      if (v.length < 10) {
                        return 'Enter a complete phone number.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  GlowingTextField(
                    hint: 'Street / House no.',
                    controller: streetCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your street address.' : null,
                  ),
                  const SizedBox(height: 12),
                  GlowingTextField(
                    hint: 'City',
                    controller: cityCtrl,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Enter your city.' : null,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    text: 'Save Address',
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      await checkout.addAddress(Address(
                        id: '',
                        label: label,
                        name: nameCtrl.text.trim(),
                        phone: phoneCtrl.text.trim(),
                        street: streetCtrl.text.trim(),
                        city: cityCtrl.text.trim(),
                      ));
                      if (sheetCtx.mounted) {
                        Navigator.pop(sheetCtx);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Payment: abhi sirf Cash on Delivery
  Widget _paymentSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryViolet, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.radio_button_checked,
              color: AppColors.primaryViolet),
          const SizedBox(width: 10),
          const Icon(Icons.money_outlined, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Cash on Delivery',
                    style: AppTextStyles.body
                        .copyWith(fontWeight: FontWeight.w600)),
                Text('Pay when your order is delivered',
                    style: AppTextStyles.caption),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Items + bill ka khulasa
  Widget _summarySection(CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          ...cart.items.map(
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${i.qty} x ',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primaryPink,
                        fontWeight: FontWeight.w700,
                      )),
                  Expanded(
                    child: Text(i.name,
                        style: AppTextStyles.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('Rs ${(i.price * i.qty).toStringAsFixed(0)}',
                      style: AppTextStyles.caption),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white10),
          _billRow('Subtotal', 'Rs ${cart.subtotal.toStringAsFixed(0)}'),
          _billRow(
            'Delivery',
            cart.deliveryFee == 0
                ? 'FREE'
                : 'Rs ${cart.deliveryFee.toStringAsFixed(0)}',
          ),
          if (cart.discount > 0)
            _billRow('Discount', '- Rs ${cart.discount.toStringAsFixed(0)}'),
          _billRow('Total', 'Rs ${cart.total.toStringAsFixed(0)}', bold: true),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: AppTextStyles.caption),
          const Spacer(),
          Text(
            value,
            style:
                (bold ? AppTextStyles.subHeading : AppTextStyles.body).copyWith(
              color: bold ? AppColors.primaryPink : AppColors.textWhite,
              fontWeight: bold ? FontWeight.w700 : null,
            ),
          ),
        ],
      ),
    );
  }

  // Neeche total + Place Order button
  Widget _bottomBar(
      BuildContext context, CheckoutProvider checkout, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total', style: AppTextStyles.caption),
                Text(
                  'Rs ${cart.total.toStringAsFixed(0)}',
                  style: AppTextStyles.subHeading
                      .copyWith(color: AppColors.primaryPink),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: PrimaryButton(
                text: 'Place Order',
                isLoading: checkout.placing,
                onPressed: () async {
                  if (checkout.selectedAddress == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Please add a delivery address first.')),
                    );
                    return;
                  }
                  final orderId = await checkout.placeOrder(cart);
                  if (!context.mounted) return;
                  if (orderId != null) {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRoutes.orderSuccess,
                      arguments: orderId,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Could not place the order. Please try again.')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
