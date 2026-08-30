import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../home/data/menu_repository.dart';
import 'booking_cubit.dart';
import 'payment_gateway_simulator.dart';
import 'order_confirmation_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class OrderSummaryStep extends StatefulWidget {
  final MenuModel menu;

  const OrderSummaryStep({Key? key, required this.menu}) : super(key: key);

  @override
  State<OrderSummaryStep> createState() => _OrderSummaryStepState();
}

class _OrderSummaryStepState extends State<OrderSummaryStep> {
  final TextEditingController _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<BookingCubit, BookingState>(
          listenWhen: (prev, curr) => prev.orderResult != curr.orderResult && curr.orderResult != null,
          listener: (context, state) {
            // Order created on backend! Time to show the simulated payment sheet
            final bookingCubit = context.read<BookingCubit>();
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (modalContext) {
                return PaymentGatewaySimulator(
                  amount: state.orderResult!.amount,
                  razorpayOrderId: state.orderResult!.razorpayOrderId,
                  onPaymentCompleted: (razorpayPaymentId) {
                    // Send to backend for cryptographic signature verification
                    bookingCubit.verifyPaymentSignature(
                      razorpayPaymentId: razorpayPaymentId,
                    );
                  },
                );
              },
            );
          },
        ),
        BlocListener<BookingCubit, BookingState>(
          listenWhen: (prev, curr) => prev.paymentSuccess != curr.paymentSuccess && curr.paymentSuccess,
          listener: (context, state) {
            // Payment verified and order confirmed on backend!
            // Pop out of the checkout wizard entirely and push confirmation page
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => OrderConfirmationScreen(
                  orderId: state.orderResult?.orderId ?? 'TIF1024',
                  tiffinName: "Home Tiffin Plan",
                  frequency: state.frequency,
                  deliveryDate: DateFormat('dd MMM, yyyy').format(state.startDate),
                  deliverySlot: state.deliverySlot,
                  totalPaid: state.orderResult?.amount ?? 0.0,
                ),
              ),
              (route) => route.isFirst,
            );
          },
        ),
        BlocListener<BookingCubit, BookingState>(
          listenWhen: (prev, curr) => prev.error != curr.error && curr.error != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.error!),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          },
        ),
      ],
      child: BlocBuilder<BookingCubit, BookingState>(
        builder: (context, state) {
          final double pricePerMeal = widget.menu.price;
          
          // Parse tab and days
          String currentTab = 'weekly';
          if (state.frequency == 'one-time') {
            currentTab = 'one-time';
          } else if (state.frequency.startsWith('monthly')) {
            currentTab = 'monthly';
          }

          int mealsCount = 1;
          if (state.frequency == 'one-time') {
            mealsCount = 1;
          } else if (state.frequency == 'weekly_5' || state.frequency == 'weekly') {
            mealsCount = 5;
          } else if (state.frequency == 'weekly_6') {
            mealsCount = 6;
          } else if (state.frequency == 'weekly_7') {
            mealsCount = 7;
          } else if (state.frequency == 'monthly_20' || state.frequency == 'monthly') {
            mealsCount = 20;
          } else if (state.frequency == 'monthly_24') {
            mealsCount = 24;
          } else if (state.frequency == 'monthly_30') {
            mealsCount = 30;
          }

          final double slotMultiplier = state.deliverySlot == 'both' ? 2.0 : 1.0;
          final int weeksMultiplier = 1;

          final double subtotal = pricePerMeal * mealsCount * slotMultiplier * weeksMultiplier * state.quantity;
          final double discount = state.appliedCoupon?.discountAmount ?? 0.0;
          final double total = subtotal - discount;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Order Summary",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Booking details description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildSummaryRow(
                        "Plan Choice",
                        "${state.frequency.toUpperCase().replaceAll('_', ' ')} Plan (${mealsCount * weeksMultiplier} Meals)",
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        "Serving Quantity",
                        "${state.quantity} Tiffin Box${state.quantity > 1 ? 'es' : ''}",
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        "First Delivery",
                        DateFormat('dd MMMM, yyyy').format(state.startDate),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        "Slot Choice",
                        state.deliverySlot.toUpperCase(),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                        "Deliver Address",
                        "${state.houseNo}, ${state.area}",
                        isMuted: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Coupon code input block
                Text(
                  "Apply Promo Code",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _couponController,
                        enabled: state.appliedCoupon == null,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          hintText: state.appliedCoupon != null
                              ? state.appliedCoupon!.code
                              : "Enter coupon (e.g. FIRSTTIFFIN)",
                          fillColor: state.appliedCoupon != null
                              ? AppTheme.primaryGreen.withOpacity(0.04)
                              : Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 52,
                      width: 110,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: state.appliedCoupon != null
                              ? AppTheme.errorColor
                              : AppTheme.primaryGreen,
                          side: BorderSide(
                            color: state.appliedCoupon != null
                                ? AppTheme.errorColor
                                : AppTheme.primaryGreen,
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        onPressed: () {
                          if (state.appliedCoupon != null) {
                            context.read<BookingCubit>().removeCoupon();
                            _couponController.clear();
                          } else {
                            context.read<BookingCubit>().applyCoupon(
                                  _couponController.text.trim(),
                                  subtotal,
                                );
                          }
                        },
                        child: Text(
                          state.appliedCoupon != null ? "Remove" : "Apply",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Pricing breakdowns
                Text(
                  "Billing Summary",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    _buildBillRow("Subtotal (${state.quantity} Tiffins)", "₹${subtotal.toStringAsFixed(0)}"),
                    const SizedBox(height: 10),
                    _buildBillRow(
                      "Coupon Discount ${state.appliedCoupon != null ? '(${state.appliedCoupon!.code})' : ''}",
                      "-₹${discount.toStringAsFixed(0)}",
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(height: 10),
                    _buildBillRow("Delivery charges", "FREE", color: AppTheme.successColor),
                    const SizedBox(height: 16),
                    const Divider(color: AppTheme.borderLight),
                    const SizedBox(height: 16),
                    _buildBillRow(
                      "Grand Total",
                      "₹${total.toStringAsFixed(0)}",
                      isBold: true,
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Proceed Button
                CustomButton(
                  text: "Proceed to Payment",
                  icon: Icons.payment,
                  isLoading: state.isLoading,
                  onPressed: () => context.read<BookingCubit>().checkout(),
                ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom > 0
                      ? MediaQuery.of(context).padding.bottom + 8
                      : 16,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isMuted = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: isMuted ? AppTheme.textMuted : AppTheme.textDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppTheme.textDark : AppTheme.textMuted,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 18 : 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.bold,
            color: color ?? AppTheme.textDark,
          ),
        ),
      ],
    );
  }
}
