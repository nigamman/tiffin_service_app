import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';

class OrderDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: BlocProvider.of<OrdersCubit>(context),
      child: _OrderDetailsView(orderId: order.id),
    );
  }
}

class _OrderDetailsView extends StatefulWidget {
  final String orderId;

  const _OrderDetailsView({Key? key, required this.orderId}) : super(key: key);

  @override
  State<_OrderDetailsView> createState() => _OrderDetailsViewState();
}

class _OrderDetailsViewState extends State<_OrderDetailsView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        if (state is OrdersLoading) {
          return const Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
          );
        }

        if (state is OrdersLoaded) {
          final order = state.activeOrders.firstWhere(
            (o) => o.id == widget.orderId,
            orElse: () => state.orderHistory.firstWhere((o) => o.id == widget.orderId),
          );

          final int activeStage = order.todayActiveStage;

          final now = DateTime.now();
          final todayNormalized = DateTime(now.year, now.month, now.day);
          final tomorrowNormalized = todayNormalized.add(const Duration(days: 1));

          // Helper to check if a date's slots are fully skipped
          bool isDateFullySkipped(OrderModel order, DateTime date) {
            final dateStr = DateFormat('yyyy-MM-dd').format(date);
            final isDaySkipped = order.skippedDates.any((d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(date));
            if (isDaySkipped) return true;

            final List<String> activeSlots = [];
            if (order.deliverySlot == 'lunch' || order.deliverySlot == 'both') {
              activeSlots.add('lunch');
            }
            if (order.deliverySlot == 'dinner' || order.deliverySlot == 'both') {
              activeSlots.add('dinner');
            }
            
            if (activeSlots.isEmpty) return false;
            return activeSlots.every((slot) => order.skippedSlots.contains("${dateStr}_$slot"));
          }

          final bool isTodayScheduled = order.isScheduledToday;
          final bool isTodaySkipped = isTodayScheduled && isDateFullySkipped(order, todayNormalized);

          final bool isTomorrowScheduled = order.orderStatus != 'cancelled' &&
              !DateTime(order.startDate.year, order.startDate.month, order.startDate.day).isAfter(tomorrowNormalized) &&
              (order.frequency == 'one-time'
                  ? DateTime(order.startDate.year, order.startDate.month, order.startDate.day).isAtSameMomentAs(tomorrowNormalized)
                  : OrderModel.isDeliveryDay(tomorrowNormalized, order.frequency));
          final bool isTomorrowSkipped = isTomorrowScheduled && isDateFullySkipped(order, tomorrowNormalized);

          final isDinnerNow = order.deliverySlot == 'dinner' || 
              (order.deliverySlot == 'both' && DateTime.now().hour >= 15);
          final String activeSlotName = isDinnerNow ? "Dinner" : "Lunch";
          final String timeRange = isDinnerNow ? "7:00 PM - 9:00 PM" : "11:30 AM - 1:30 PM";

          return Scaffold(
            backgroundColor: AppTheme.backgroundLight,
            appBar: AppBar(
              title: const Text("Order Status Details"),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Order Status Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.015),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              order.frequency == 'one-time' ? "One-Time Meal" : "${order.frequency.toUpperCase()} PLAN",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: order.orderStatus == 'cancelled'
                                    ? AppTheme.errorColor.withOpacity(0.08)
                                    : AppTheme.successColor.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                order.orderStatus.toUpperCase(),
                                style: TextStyle(
                                  color: order.orderStatus == 'cancelled' ? AppTheme.errorColor : AppTheme.successColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Order ID: #${order.id.toUpperCase().substring(order.id.length - 6)}",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const Divider(height: 24, color: AppTheme.borderLight),
                        _buildInfoRow(Icons.restaurant_menu_outlined, "Order Name", "Home Tiffin Meal (${order.quantity} Box)"),
                        _buildInfoRow(Icons.calendar_today_outlined, "Order Date", DateFormat('dd MMM yyyy').format(order.startDate)),
                        _buildInfoRow(Icons.access_time_outlined, "Delivery Slot", "${order.deliverySlot.toUpperCase()} (${order.deliverySlot == 'lunch' ? '11:30 AM - 1:30 PM' : order.deliverySlot == 'dinner' ? '7:00 PM - 9:00 PM' : 'Lunch & Dinner'})"),
                        _buildInfoRow(Icons.phone_outlined, "Phone No", "+91 ${order.contactPhone}"),
                        _buildInfoRow(Icons.currency_rupee_outlined, "Total Amount", "₹${order.finalAmount.toStringAsFixed(0)}"),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          "Address",
                          [order.houseNo, order.area, order.landmark].where((s) => s.isNotEmpty).join(', ').isEmpty
                              ? "Kalyanpur, Kanpur"
                              : [order.houseNo, order.area, order.landmark].where((s) => s.isNotEmpty).join(', '),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Today's/Tomorrow's Status Tracker
                  if (isTodayScheduled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTodaySkipped ? "Today's Delivery Skipped" : "Track Today's $activeSlotName Delivery",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isTodaySkipped
                                ? "You chose to skip your delivery today."
                                : "Delivery window: $timeRange",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: isTodaySkipped ? AppTheme.errorColor : const Color(0xFFC3A575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (!isTodaySkipped) ...[
                            const SizedBox(height: 24),
                            // Horizontal Animation Slider Track
                            Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                Container(
                                  width: double.infinity,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: AppTheme.borderLight,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 1000),
                                      curve: Curves.easeInOutQuad,
                                      width: constraints.maxWidth * (activeStage / 3.0),
                                      height: 4,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreen,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(4, (index) {
                                    final isCompleted = index <= activeStage;
                                    return Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: isCompleted ? AppTheme.primaryGreen : Colors.white,
                                        border: Border.all(
                                          color: isCompleted ? AppTheme.primaryGreen : AppTheme.borderLight,
                                          width: 2.5,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                    );
                                  }),
                                ),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SizedBox(
                                      width: constraints.maxWidth,
                                      child: AnimatedAlign(
                                        duration: const Duration(milliseconds: 1000),
                                        curve: Curves.easeInOutQuad,
                                        alignment: Alignment(-1.0 + (2.0 * (activeStage / 3.0)), 0.0),
                                        child: Container(
                                          transform: Matrix4.translationValues(0, -2, 0),
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(
                                            color: AppTheme.secondaryMarigold,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.secondaryMarigold,
                                                blurRadius: 10,
                                                offset: Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.delivery_dining,
                                            color: Color(0xFF0F3A20),
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildTrackNodeLabel("Placed", 0, activeStage),
                                _buildTrackNodeLabel("Preparing", 1, activeStage),
                                _buildTrackNodeLabel("Out for Delivery", 2, activeStage),
                                _buildTrackNodeLabel("Delivered", 3, activeStage),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ] else if (isTomorrowScheduled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isTomorrowSkipped ? Icons.block_outlined : Icons.calendar_today_outlined,
                            color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.primaryGreen,
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Tomorrow's Delivery Status",
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isTomorrowSkipped ? "SKIPPED (Plan extended by 1 day)" : "SCHEDULED (Lunch: 11:30 AM / Dinner: 7:00 PM)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 3. Subscription Info & Tiffin Counter
                  if (order.frequency != 'one-time') ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Tiffins Remaining",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Remaining Tiffins",
                                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              Text(
                                "${order.remainingMeals} Left",
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Tiffins in Plan",
                                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              Text(
                                "${order.totalMeals} Meals",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress Bar
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.borderLight.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: order.progressPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryGreen,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Center(
                            child: Text(
                              "${(order.progressPercent * 100).toStringAsFixed(0)}% consumed",
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }

        return const Scaffold(
          body: Center(child: Text("Error fetching order status details.")),
        );
      },
    );
  }

  Widget _buildTrackNodeLabel(String text, int stageIndex, int activeStage) {
    final isActive = activeStage == stageIndex;
    final isCompleted = activeStage >= stageIndex;
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 10,
        fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
        color: isActive 
            ? AppTheme.secondaryMarigold 
            : (isCompleted ? AppTheme.primaryGreen : AppTheme.textMuted),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryGreen),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
