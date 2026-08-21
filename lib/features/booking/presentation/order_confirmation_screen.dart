import 'package:flutter/material.dart';
import '../../home/presentation/main_layout.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;
  final String tiffinName;
  final String frequency;
  final String deliveryDate;
  final String deliverySlot;
  final double totalPaid;

  const OrderConfirmationScreen({
    Key? key,
    required this.orderId,
    required this.tiffinName,
    required this.frequency,
    required this.deliveryDate,
    required this.deliverySlot,
    required this.totalPaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Animated Success Check
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: AppTheme.successColor,
                  size: 72,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "🎉 Tiffin Booked!",
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                "Your tiffin booking has been confirmed successfully.",
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 36),

              // Order Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight),
                ),
                child: Column(
                  children: [
                    _buildDetailRow("Order ID", "#${orderId.toUpperCase()}"),
                    const SizedBox(height: 12),
                    _buildDetailRow("Tiffin Plan", "${frequency.toUpperCase()} Tiffin"),
                    const SizedBox(height: 12),
                    _buildDetailRow("Next Delivery", "$deliveryDate • ${deliverySlot.toUpperCase()}"),
                    const SizedBox(height: 12),
                    _buildDetailRow("Total Paid", "₹${totalPaid.toStringAsFixed(0)}", isHighlight: true),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // Bottom Actions
              CustomButton(
                text: "View Orders",
                icon: Icons.receipt_long,
                onPressed: () {
                  // Direct to main layout, showing the second tab (Orders)
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainLayout(initialIndex: 1),
                    ),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () {
                    // Direct to main layout home tab
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MainLayout(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    "Back to Home",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 14,
            fontFamily: 'PlusJakartaSans',
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isHighlight ? 16 : 14,
            color: isHighlight ? AppTheme.secondaryMarigold : AppTheme.textDark,
            fontFamily: 'Outfit',
          ),
        ),
      ],
    );
  }
}
