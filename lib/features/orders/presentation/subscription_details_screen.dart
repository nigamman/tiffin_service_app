import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/notification_overlay.dart';
import 'package:google_fonts/google_fonts.dart';

class SubscriptionDetailsScreen extends StatelessWidget {
  final OrderModel order;

  const SubscriptionDetailsScreen({Key? key, required this.order}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: BlocProvider.of<OrdersCubit>(context),
      child: _SubscriptionDetailsView(orderId: order.id),
    );
  }
}

class _SubscriptionDetailsView extends StatefulWidget {
  final String orderId;

  const _SubscriptionDetailsView({Key? key, required this.orderId}) : super(key: key);

  @override
  State<_SubscriptionDetailsView> createState() => _SubscriptionDetailsViewState();
}

class _SubscriptionDetailsViewState extends State<_SubscriptionDetailsView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        String titleText = "Subscription Details";
        if (state is OrdersLoaded) {
          final currentOrder = state.activeOrders.firstWhere(
            (o) => o.id == widget.orderId,
            orElse: () => state.orderHistory.firstWhere((o) => o.id == widget.orderId),
          );
          if (currentOrder.frequency == 'one-time') {
            titleText = "Order Details";
          }
        }

        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: Text(titleText),
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: BlocBuilder<OrdersCubit, OrdersState>(
            builder: (context, state) {
              if (state is OrdersLoading) {
                return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
              }

              if (state is OrdersLoaded) {
                final currentOrder = state.activeOrders.firstWhere(
                  (o) => o.id == widget.orderId,
                  orElse: () => state.orderHistory.firstWhere((o) => o.id == widget.orderId),
                );

                return _buildContent(context, currentOrder);
              }

              return const Center(child: Text("Failed to load details."));
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, OrderModel order) {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);

    final totalMeals = order.totalMeals;
    final remainingMeals = order.remainingMeals;
    final double progressPercent = order.progressPercent;

    final int maxDays = order.frequency == 'one-time' ? 1 : order.remainingMeals;
    final int daysLimit = maxDays < 7 ? maxDays : 7;

    // Helper to check if a date is fully skipped
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

    // List of next delivery days to show (loop until we collect daysLimit of non-skipped scheduled meals)
    final List<DateTime> nextDays = [];
    DateTime checkDate = todayNormalized.isBefore(DateTime(order.startDate.year, order.startDate.month, order.startDate.day))
        ? DateTime(order.startDate.year, order.startDate.month, order.startDate.day)
        : todayNormalized;
    
    int scheduledMealsCount = 0;
    int safetyLimit = 30; // safety ceiling to prevent infinite loop

    while (scheduledMealsCount < daysLimit && safetyLimit > 0) {
      if (_isDeliveryDay(checkDate, order.frequency)) {
        nextDays.add(checkDate);
        if (!isDateFullySkipped(order, checkDate)) {
          scheduledMealsCount++;
        }
      }
      checkDate = checkDate.add(const Duration(days: 1));
      safetyLimit--;
    }

    // Count skipped slots in these days
    int skipCount = 0;
    for (final day in nextDays) {
      final isDaySkipped = order.skippedDates.any((d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(day));
      if (isDaySkipped) {
        skipCount++;
        continue;
      }
      for (final slot in ['lunch', 'dinner']) {
        final slotKey = "${DateFormat('yyyy-MM-dd').format(day)}_$slot";
        if (order.skippedSlots.contains(slotKey)) {
          skipCount++;
        }
      }
    }

    final bool isOneTime = order.frequency == 'one-time';

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Subscription Info Overview Card
          _buildPlanOverviewCard(context, order, remainingMeals, totalMeals, progressPercent),

          if (!isOneTime) ...[
            // 2. Next 7 Days Delivery Schedule
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        daysLimit == 1 ? "Next Day's Schedule" : "Next $daysLimit Days Schedule",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFC3A575).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "2 Hrs Cutoff Enforced",
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFC3A575),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Weekly Skip Limit: $skipCount / 1 used (Pausing extends your plan)",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: skipCount >= 1 ? AppTheme.errorColor : AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            _buildSevenDayScheduleList(context, order, skipCount, nextDays),
          ],

          // 3. Billing & Address section
          _buildBillingDetailsCard(order),
          
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildPlanOverviewCard(
    BuildContext context,
    OrderModel order,
    int remainingMeals,
    int totalMeals,
    double progressPercent,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.frequency == 'one-time'
                        ? "One-Time Delivery"
                        : "${order.frequency.toUpperCase().replaceAll('_', ' ')} Plan",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Order ID: #${order.id.toUpperCase().substring(order.id.length - 6)}",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "ACTIVE",
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          
          const Divider(height: 32, color: AppTheme.borderLight),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDetailMiniColumn("Delivered Slot", order.deliverySlot.toUpperCase()),
              _buildDetailMiniColumn("Quantity", "${order.quantity} Tiffin Box"),
              _buildDetailMiniColumn("Start Date", DateFormat('dd MMM yyyy').format(order.startDate)),
            ],
          ),

          if (order.frequency != 'one-time') ...[
            const SizedBox(height: 24),
            // Progress Tracker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Subscription Progress",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "$remainingMeals of $totalMeals meals left",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.borderLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailMiniColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSevenDayScheduleList(BuildContext context, OrderModel order, int skipCount, List<DateTime> nextDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: nextDays.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final dayDate = nextDays[index];
        final dayName = DateFormat('EEEE').format(dayDate);
        final dateLabel = DateFormat('dd MMM').format(dayDate);
        
        final isToday = dayDate.isAtSameMomentAs(today);

        // Check if the entire day is skipped in order.skippedDates
        final isFullDaySkipped = order.skippedDates.any(
          (d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(dayDate),
        );

        // Sub-elements for active slots
        final List<String> activeSlots = [];
        if (order.deliverySlot == 'lunch' || order.deliverySlot == 'both') {
          activeSlots.add('lunch');
        }
        if (order.deliverySlot == 'dinner' || order.deliverySlot == 'both') {
          activeSlots.add('dinner');
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
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
              // Header Day/Date Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        isToday ? "Today" : dayName,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isToday ? AppTheme.primaryGreen : AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        dateLabel,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (isFullDaySkipped)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "DAY SKIPPED",
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.errorColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Dynamic slots list for this day
              ...activeSlots.map((slot) {
                final slotKey = "${DateFormat('yyyy-MM-dd').format(dayDate)}_$slot";
                final isSlotSkipped = isFullDaySkipped || order.skippedSlots.contains(slotKey);
                
                // Determine skip cutoff time for this slot
                int cutoffHour = slot == 'lunch' ? 9 : 17; // 9:30 AM or 5:00 PM
                int cutoffMinute = slot == 'lunch' ? 30 : 0;
                final deliveryStart = slot == 'lunch' ? "11:30 AM" : "7:00 PM";
                
                final slotCutoff = DateTime(dayDate.year, dayDate.month, dayDate.day, cutoffHour, cutoffMinute);
                final canToggle = now.isBefore(slotCutoff);

                return Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFBFBF9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        slot == 'lunch' ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                        size: 18,
                        color: slot == 'lunch' ? Colors.orange : Colors.indigo,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              slot == 'lunch' ? "Lunch Delivery" : "Dinner Delivery",
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSlotSkipped ? AppTheme.textMuted : AppTheme.textDark,
                                decoration: isSlotSkipped ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            Text(
                              isSlotSkipped 
                                  ? "Skipped - subscription extended" 
                                  : "Starts at $deliveryStart",
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: isSlotSkipped ? AppTheme.errorColor : AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Action Toggle Button
                      if (canToggle && !isFullDaySkipped) ...[
                        Builder(
                          builder: (context) {
                            final bool hasReachedSkipLimit = skipCount >= 1;
                            final bool isSkipDisabled = !isSlotSkipped && hasReachedSkipLimit;

                            return SizedBox(
                              height: 32,
                              child: ElevatedButton(
                                onPressed: isSkipDisabled
                                    ? null
                                    : () {
                                        if (isSlotSkipped) {
                                          context.read<OrdersCubit>().unskipSlot(order.id, slotKey);
                                          NotificationOverlay.show(
                                            context,
                                            title: "Delivery Restored",
                                            message: "${slot.toUpperCase()} delivery restored for $dateLabel.",
                                            icon: Icons.check_circle_outline,
                                          );
                                        } else {
                                          context.read<OrdersCubit>().skipSlot(order.id, slotKey);
                                          NotificationOverlay.show(
                                            context,
                                            title: "Delivery Paused",
                                            message: "${slot.toUpperCase()} delivery skipped for $dateLabel.",
                                            icon: Icons.pause_circle_outline,
                                          );
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSlotSkipped 
                                      ? AppTheme.primaryGreen 
                                      : (isSkipDisabled ? AppTheme.borderLight : Colors.white),
                                  foregroundColor: isSlotSkipped 
                                      ? Colors.white 
                                      : (isSkipDisabled ? AppTheme.textMuted : AppTheme.secondaryMarigold),
                                  elevation: 0,
                                  side: BorderSide(
                                    color: isSlotSkipped 
                                        ? Colors.transparent 
                                        : (isSkipDisabled ? Colors.transparent : AppTheme.secondaryMarigold),
                                    width: 1.2,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text(
                                  isSlotSkipped ? "Unskip" : (isSkipDisabled ? "Locked" : "Skip"),
                                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          }
                        ),
                      ]
                      else ...[
                        // Finalized status icon/badge
                        Row(
                          children: [
                            Icon(
                              isSlotSkipped ? Icons.block_outlined : Icons.lock_outline,
                              size: 13,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSlotSkipped 
                                  ? "Skipped" 
                                  : (dayDate.isBefore(today) ? "Delivered" : "Finalized"),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isSlotSkipped ? AppTheme.errorColor : AppTheme.successColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBillingDetailsCard(OrderModel order) {
    final String daysLabel = order.frequency == 'one-time' ? "1 Day" : "${order.mealsCount} Days";
    final slotMultiplier = order.deliverySlot == 'both' ? 2 : 1;
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Address & Billing Summary",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: AppTheme.textDark,
            ),
          ),
          
          const Divider(height: 24, color: AppTheme.borderLight),

          _buildBillingRow("Price Per Thali", "₹${order.pricePerMeal.toStringAsFixed(0)}"),
          const SizedBox(height: 10),
          _buildBillingRow("Plan Days", daysLabel),
          const SizedBox(height: 10),
          _buildBillingRow("Slots per Day", "$slotMultiplier Slot(s)"),
          const SizedBox(height: 10),
          _buildBillingRow("Quantity", "${order.quantity} Tiffin Box(es)"),
          const SizedBox(height: 10),
          _buildBillingRow("Subtotal", "₹${order.totalAmount.toStringAsFixed(0)}"),
          
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 10),
            _buildBillingRow("Coupon Discount", "-₹${order.discountAmount.toStringAsFixed(0)}", isDiscount: true),
          ],
          
          const Divider(height: 24, color: AppTheme.borderLight),

          _buildBillingRow("Total Paid", "₹${order.finalAmount.toStringAsFixed(0)}", isHighlight: true),
          const SizedBox(height: 10),
          _buildBillingRow("Contact Phone", order.contactPhone),
        ],
      ),
    );
  }

  Widget _buildBillingRow(String label, String value, {bool isHighlight = false, bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isHighlight 
                  ? AppTheme.secondaryMarigold 
                  : (isDiscount ? AppTheme.errorColor : AppTheme.textDark),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }



}

bool _isDeliveryDay(DateTime date, String frequency) {
  final weekday = date.weekday; // 1 = Monday, ..., 7 = Sunday
  
  if (frequency.contains('_5') || frequency == 'weekly' || frequency == 'monthly') {
    return weekday >= 1 && weekday <= 5;
  } else if (frequency.contains('_6')) {
    return weekday >= 1 && weekday <= 6;
  }
  return true;
}
