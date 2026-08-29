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
    final startNormalized = DateTime(order.startDate.year, order.startDate.month, order.startDate.day);

    // Dynamic remaining meals calculation
    int deliveredMeals = 0;
    final slotMultiplier = order.deliverySlot == 'both' ? 2 : 1;
    final int weeksMultiplier = 1;
    final totalMeals = order.mealsCount * slotMultiplier * weeksMultiplier;
      if (!todayNormalized.isBefore(startNormalized)) {
        int totalElapsedSlots = 0;
        final currentHour = now.hour;
        final currentMinute = now.minute;
        final currentFloatTime = currentHour + (currentMinute / 60.0);

        for (int i = 0; i <= todayNormalized.difference(startNormalized).inDays; i++) {
          final checkDate = startNormalized.add(Duration(days: i));
          if (_isDeliveryDay(checkDate, order.frequency)) {
            if (checkDate.isBefore(todayNormalized)) {
              // Past day: all slots elapsed
              totalElapsedSlots += (order.deliverySlot == 'both' ? 2 : 1);
            } else if (checkDate.isAtSameMomentAs(todayNormalized)) {
              // Today: check which slots have actually finished delivery window
              if (order.deliverySlot == 'lunch') {
                if (currentFloatTime >= 13.5) { // Lunch ends at 1:30 PM (13.5)
                  totalElapsedSlots += 1;
                }
              } else if (order.deliverySlot == 'dinner') {
                if (currentFloatTime >= 21.0) { // Dinner ends at 9:00 PM (21.0)
                  totalElapsedSlots += 1;
                }
              } else if (order.deliverySlot == 'both') {
                if (currentFloatTime >= 21.0) {
                  totalElapsedSlots += 2; // both lunch and dinner ended
                } else if (currentFloatTime >= 13.5) {
                  totalElapsedSlots += 1; // only lunch ended
                }
              }
            }
          }
        }

        final multiplier = order.deliverySlot == 'both' ? 2 : 1;
        
        final elapsedFullDaySkips = order.skippedDates
            .where((d) => !d.isAfter(todayNormalized))
            .length * multiplier;
            
        int elapsedSlotSkips = 0;
        for (final slotKey in order.skippedSlots) {
          try {
            final dateStr = slotKey.split('_')[0];
            final slotDate = DateTime.parse(dateStr);
            if (!slotDate.isAfter(todayNormalized)) {
              elapsedSlotSkips++;
            }
          } catch (_) {}
        }
        
        final totalSkips = elapsedFullDaySkips + elapsedSlotSkips;
        deliveredMeals = (totalElapsedSlots - totalSkips).clamp(0, totalMeals);
      }

    final remainingMeals = (totalMeals - deliveredMeals).clamp(0, totalMeals);
    final double progressPercent = totalMeals > 0 ? remainingMeals / totalMeals : 0;

    // Count skipped slots in these 7 days
    int skipCount = 0;
    final List<DateTime> next7Days = List.generate(7, (i) => todayNormalized.add(Duration(days: i)));
    for (final day in next7Days) {
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

          // 2. Schedule or One-time Details
          if (isOneTime)
            _buildOneTimeDeliveryStatusCard(order)
          else ...[
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
                        "Next 7 Days Schedule",
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

            _buildSevenDayScheduleList(context, order, skipCount),
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

  Widget _buildSevenDayScheduleList(BuildContext context, OrderModel order, int skipCount) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDateNormalized = DateTime(order.startDate.year, order.startDate.month, order.startDate.day);
    final DateTime scheduleStart = today.isBefore(startDateNormalized) ? startDateNormalized : today;

    // List of next 7 delivery days
    final List<DateTime> nextDays = [];
    DateTime checkDate = scheduleStart;
    while (nextDays.length < 7) {
      if (_isDeliveryDay(checkDate, order.frequency)) {
        nextDays.add(checkDate);
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }

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

  Widget _buildOneTimeDeliveryStatusCard(OrderModel order) {
    return OneTimeOrderTracker(order: order);
  }
}

class OneTimeOrderTracker extends StatefulWidget {
  final OrderModel order;
  const OneTimeOrderTracker({Key? key, required this.order}) : super(key: key);

  @override
  State<OneTimeOrderTracker> createState() => _OneTimeOrderTrackerState();
}

class _OneTimeOrderTrackerState extends State<OneTimeOrderTracker> {
  int _activeStage = 0; // 0 = Placed, 1 = Preparing, 2 = Dispatched, 3 = Delivered
  bool _isManualOverride = false;

  @override
  void initState() {
    super.initState();
    _calculateCurrentStage();
  }

  void _calculateCurrentStage() {
    if (_isManualOverride) return;
    
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deliveryDate = DateTime(widget.order.startDate.year, widget.order.startDate.month, widget.order.startDate.day);

    if (today.isAfter(deliveryDate)) {
      _activeStage = 3;
      return;
    }
    if (today.isBefore(deliveryDate)) {
      _activeStage = 0;
      return;
    }

    // It is today! Check the hours
    final hour = now.hour;
    final minute = now.minute;
    final double timeOfDay = hour + (minute / 60.0);

    if (widget.order.deliverySlot == 'dinner') {
      if (timeOfDay < 19.0) {
        _activeStage = 0; // Placed (before 7:00 PM)
      } else if (timeOfDay >= 19.0 && timeOfDay < 19.75) {
        _activeStage = 1; // Preparing (7:00 PM - 7:45 PM)
      } else if (timeOfDay >= 19.75 && timeOfDay < 21.0) {
        _activeStage = 2; // Dispatched (7:45 PM - 9:00 PM)
      } else {
        _activeStage = 3; // Delivered (after 9:00 PM)
      }
    } else {
      // Lunch
      if (timeOfDay < 11.5) {
        _activeStage = 0; // Placed (before 11:30 AM)
      } else if (timeOfDay >= 11.5 && timeOfDay < 12.25) {
        _activeStage = 1; // Preparing (11:30 AM - 12:15 PM)
      } else if (timeOfDay >= 12.25 && timeOfDay < 13.5) {
        _activeStage = 2; // Dispatched (12:15 PM - 1:30 PM)
      } else {
        _activeStage = 3; // Delivered (after 1:30 PM)
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliveryDate = DateTime(widget.order.startDate.year, widget.order.startDate.month, widget.order.startDate.day);
    final String formattedDate = DateFormat('EEEE, dd MMM').format(deliveryDate);
    final String timeRange = widget.order.deliverySlot == 'lunch' ? "12:00 PM - 2:00 PM" : "7:30 PM - 9:30 PM";

    return Column(
      children: [
        // 1. Swiggy style sliding bike track animation card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(24),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Track Tiffin Delivery",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  if (_isManualOverride)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryMarigold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "TEST SIMULATION ACTIVE",
                        style: GoogleFonts.poppins(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.secondaryMarigold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Horizontal Animation Slider Track
              Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Track background
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.borderLight,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Track Green active progress
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final double fullWidth = constraints.maxWidth;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 1000),
                        curve: Curves.easeInOutQuad,
                        width: fullWidth * (_activeStage / 3.0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),

                  // Node checkpoints
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      final isCurrentOrPast = index <= _activeStage;
                      final isActive = index == _activeStage;
                      return Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isCurrentOrPast ? AppTheme.primaryGreen : Colors.white,
                          border: Border.all(
                            color: isCurrentOrPast ? AppTheme.primaryGreen : AppTheme.borderLight,
                            width: 2.5,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: isActive ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.4),
                              blurRadius: 6,
                              spreadRadius: 3,
                            ),
                          ] : null,
                        ),
                      );
                    }),
                  ),

                  // Dynamic Alignment Sliding Tiffin Bike Icon!
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 1000),
                          curve: Curves.easeInOutQuad,
                          alignment: Alignment(-1.0 + (2.0 * (_activeStage / 3.0)), 0.0),
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
                  _buildTrackNodeLabel("Placed", 0),
                  _buildTrackNodeLabel("Cooking", 1),
                  _buildTrackNodeLabel("On Way", 2),
                  _buildTrackNodeLabel("Delivered", 3),
                ],
              ),
            ],
          ),
        ),

        // 2. Vertical Stepper Details Card
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(24),
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
                "Status Detail ($formattedDate)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 20),
              
              _buildTrackerStep(
                stepIndex: 0,
                icon: Icons.check,
                title: "Order Placed",
                subtitle: "Tiffin meal order accepted at Atithi Bhoj.",
                isCompleted: true,
                isActive: false,
                isLast: false,
              ),
              _buildTrackerStep(
                stepIndex: 1,
                icon: Icons.restaurant_menu_outlined,
                title: "Meal Preparing",
                subtitle: "Our chefs are cooking your fresh home tiffin.",
                isCompleted: _activeStage >= 1,
                isActive: _activeStage == 0,
                isLast: false,
              ),
              _buildTrackerStep(
                stepIndex: 2,
                icon: Icons.delivery_dining_outlined,
                title: "Out for Delivery",
                subtitle: "Delivery partner has picked up your tiffin and is on the way.",
                isCompleted: _activeStage >= 2,
                isActive: _activeStage == 1,
                isLast: false,
              ),
              _buildTrackerStep(
                stepIndex: 3,
                icon: Icons.assignment_turned_in_outlined,
                title: "Delivered",
                subtitle: "Tiffin dropped off at your address. Enjoy your meal!",
                isCompleted: _activeStage >= 3,
                isActive: _activeStage == 2,
                isLast: true,
              ),
            ],
          ),
        ),

        // 3. Interactive simulation controller for the user
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F6F0),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                "Simulate Swiggy Live Tracking Demo",
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSimulateButton("Placed", 0),
                  _buildSimulateButton("Cooking", 1),
                  _buildSimulateButton("On Way", 2),
                  _buildSimulateButton("Delivered", 3),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTrackNodeLabel(String text, int stageIndex) {
    final isActive = _activeStage == stageIndex;
    final isCompleted = _activeStage >= stageIndex;
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

  Widget _buildSimulateButton(String text, int targetStage) {
    final isCurrent = _activeStage == targetStage;
    return InkWell(
      onTap: () {
        setState(() {
          _isManualOverride = true;
          _activeStage = targetStage;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isCurrent ? AppTheme.primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isCurrent ? Colors.white : AppTheme.textDark,
          ),
        ),
      ),
    );
  }

  Widget _buildTrackerStep({
    required int stepIndex,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isLast,
  }) {
    final Color stepColor = isCompleted 
        ? AppTheme.primaryGreen 
        : (isActive ? AppTheme.secondaryMarigold : AppTheme.borderLight);
        
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppTheme.primaryGreen.withOpacity(0.06)
                    : (isActive ? AppTheme.secondaryMarigold.withOpacity(0.08) : Colors.transparent),
                border: Border.all(
                  color: isActive ? Colors.transparent : stepColor,
                  width: 1.5,
                ),
                shape: BoxShape.circle,
              ),
              child: isActive
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(AppTheme.secondaryMarigold),
                            ),
                          ),
                          Icon(
                            icon,
                            size: 9,
                            color: AppTheme.secondaryMarigold,
                          ),
                        ],
                      ),
                    )
                  : Icon(
                      isCompleted ? Icons.check : icon,
                      size: 13,
                      color: stepColor,
                    ),
            ),
            if (!isLast)
              Container(
                width: 1.5,
                height: 36,
                color: isCompleted ? AppTheme.primaryGreen : AppTheme.borderLight,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isCompleted || isActive ? AppTheme.textDark : AppTheme.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: AppTheme.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],
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
