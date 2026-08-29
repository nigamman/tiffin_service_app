import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class PaymentGatewaySimulator extends StatefulWidget {
  final double amount;
  final String razorpayOrderId;
  final Function(String paymentId) onPaymentCompleted;

  const PaymentGatewaySimulator({
    Key? key,
    required this.amount,
    required this.razorpayOrderId,
    required this.onPaymentCompleted,
  }) : super(key: key);

  @override
  State<PaymentGatewaySimulator> createState() => _PaymentGatewaySimulatorState();
}

class _PaymentGatewaySimulatorState extends State<PaymentGatewaySimulator> {
  bool _isLoading = false;
  String _selectedMethod = 'upi'; // 'upi', 'card', 'netbanking'

  void _processPayment() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay processing payment
    await Future.delayed(const Duration(milliseconds: 1800));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
      Navigator.pop(context); // Close bottom sheet
      
      // Generate a mock payment ID
      final mockPaymentId = 'pay_mock_${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
      widget.onPaymentCompleted(mockPaymentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D1D30), // Razorpay dark navy background theme
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        top: 20,
        left: 20,
        right: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.network(
                'https://upload.wikimedia.org/wikipedia/commons/8/89/Razorpay_logo.svg',
                height: 24,
                width: 100,
                color: Colors.white,
                errorBuilder: (c, e, s) => const Text(
                  "Razorpay",
                  style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white60),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Payment cancelled by user"),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 20),

          // Total Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "PAYING",
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                  ),
                  Text(
                    "Atithi Bhoj Tiffin Service",
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${widget.amount.toStringAsFixed(2)}",
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    "Convenience fee: ₹0.00",
                    style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Order ID: ${widget.razorpayOrderId}",
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
          const SizedBox(height: 24),

          const Text(
            "CHOOSE PAYMENT METHOD",
            style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),

          // Methods List
          _buildMethodTile(
            title: "UPI (Google Pay, PhonePe, Paytm)",
            subtitle: "Instant payment using UPI apps",
            icon: Icons.qr_code,
            value: "upi",
          ),
          _buildMethodTile(
            title: "Card (Visa, MasterCard, RuPay)",
            subtitle: "Debit or Credit cards",
            icon: Icons.credit_card,
            value: "card",
          ),
          _buildMethodTile(
            title: "Net Banking (SBI, HDFC, ICICI)",
            subtitle: "Redirects to bank portals",
            icon: Icons.account_balance,
            value: "netbanking",
          ),
          const SizedBox(height: 32),

          // Pay CTA
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF), // Razorpay Blue
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _isLoading ? null : _processPayment,
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(
                      "PAY NOW  •  ₹${widget.amount.toStringAsFixed(0)}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              "🔒 Secured by Razorpay",
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMethodTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String value,
  }) {
    final isSelected = _selectedMethod == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = value;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0066FF) : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0066FF) : Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            Radio<String>(
              value: value,
              groupValue: _selectedMethod,
              activeColor: const Color(0xFF0066FF),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedMethod = val;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
