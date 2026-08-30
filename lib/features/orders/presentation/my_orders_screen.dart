import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/notification_overlay.dart';
import 'subscription_details_screen.dart';


class MyOrdersScreen extends StatefulWidget {
  const MyOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends State<MyOrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<OrdersCubit>().loadOrders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("My Bookings"),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryGreen,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(),
          tabs: const [
            Tab(text: "My Subscriptions"),
            Tab(text: "One-Time Orders"),
          ],
        ),
      ),
      body: BlocListener<OrdersCubit, OrdersState>(
        listener: (context, state) {
          if (state is OrdersError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        },
        child: BlocBuilder<OrdersCubit, OrdersState>(
          builder: (context, state) {
            if (state is OrdersLoading) {
              return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
            } else if (state is OrdersLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildActivePlansList(state.activeOrders),
                  _buildHistoryList(state.orderHistory),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildActivePlansList(List<OrderModel> activeOrders) {
    if (activeOrders.isEmpty) {
      return _buildEmptyState("No subscriptions found", "Subscribe to a daily, weekly, or monthly plan today!");
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrdersCubit>().loadOrders(),
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          final order = activeOrders[index];
          
          final now = DateTime.now();
          final todayNormalized = DateTime(now.year, now.month, now.day);
          final startNormalized = DateTime(order.startDate.year, order.startDate.month, order.startDate.day);
          
          final totalMeals = order.totalMeals;
          final deliveredMeals = order.deliveredMeals;
          final remainingMeals = order.remainingMeals;
          final double progressPercent = order.progressPercent;

          // Determine the cutoff time for today's delivery (2 hours before delivery slot)
          int cutoffHour = 9; // 9:30 AM
          int cutoffMinute = 30;
          String cutoffText = "9:30 AM";
          if (order.deliverySlot == 'dinner') {
            cutoffHour = 17; // 5:00 PM
            cutoffMinute = 0;
            cutoffText = "5:00 PM";
          } else if (order.deliverySlot == 'both') {
            cutoffHour = 9; // 9:30 AM for lunch
            cutoffMinute = 30;
            cutoffText = "9:30 AM";
          }
          
          final todayCutoff = DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);
          
          DateTime targetSkipDate;
          if (startNormalized.isAfter(todayNormalized)) {
            targetSkipDate = startNormalized;
          } else if (now.isBefore(todayCutoff)) {
            targetSkipDate = todayNormalized;
          } else {
            targetSkipDate = todayNormalized.add(const Duration(days: 1));
          }
          
          final isTargetSkipped = order.skippedDates.any(
            (d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(targetSkipDate),
          );
          
          final isTargetToday = DateTime(targetSkipDate.year, targetSkipDate.month, targetSkipDate.day)
              .isAtSameMomentAs(todayNormalized);
          final isTargetTomorrow = DateTime(targetSkipDate.year, targetSkipDate.month, targetSkipDate.day)
              .isAtSameMomentAs(todayNormalized.add(const Duration(days: 1)));
          
          final String dayLabel = isTargetToday 
              ? "Today" 
              : (isTargetTomorrow ? "Tomorrow" : DateFormat('EEEE, dd MMM').format(targetSkipDate));

          final String slotTimingText;
          if (order.deliverySlot == 'lunch') {
            slotTimingText = "11:30 AM - 1:30 PM";
          } else if (order.deliverySlot == 'dinner') {
            slotTimingText = "7:00 PM - 9:00 PM";
          } else {
            slotTimingText = "Lunch: 11:30 AM - 1:30 PM & Dinner: 7:00 PM - 9:00 PM";
          }

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
          final bool hasReachedSkipLimit = skipCount >= 1;

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubscriptionDetailsScreen(order: order),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20.0),
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
                // Card Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: order.frequency == 'one-time'
                            ? AppTheme.secondaryMarigold.withOpacity(0.08)
                            : AppTheme.primaryGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        order.frequency == 'one-time'
                            ? "ONE-TIME MEAL"
                            : "${order.frequency.toUpperCase()} SUBSCRIPTION",
                        style: TextStyle(
                          color: order.frequency == 'one-time'
                              ? AppTheme.secondaryMarigold
                              : AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: AppTheme.successColor, size: 14),
                        SizedBox(width: 6),
                        Text(
                          "Active",
                          style: TextStyle(
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Meal Title
                Text(
                  "Home Tiffin Meal  •  ${order.quantity} Box",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 12),

                if (order.frequency != 'one-time') ...[
                  // Premium Progress Tracker
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Subscription Progress",
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      Text(
                        "$remainingMeals of $totalMeals meals left",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
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
                  const Divider(height: 32, color: AppTheme.borderLight),
                ] else ...[
                  const Divider(height: 24, color: AppTheme.borderLight),
                ],
                
                // Timeline Delivery details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isTargetSkipped 
                            ? AppTheme.errorColor.withOpacity(0.06)
                            : AppTheme.primaryGreen.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTargetSkipped ? Icons.block_outlined : Icons.delivery_dining_outlined,
                        size: 18,
                        color: isTargetSkipped ? AppTheme.errorColor : AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTargetSkipped
                                ? "$dayLabel's Delivery Skipped"
                                : "Scheduled $dayLabel",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isTargetSkipped ? AppTheme.errorColor : AppTheme.textDark,
                            ),
                          ),
                          Text(
                            isTargetSkipped
                                ? "You will not receive tiffin box for $dayLabel's ${order.deliverySlot} slot."
                                : "Delivered $dayLabel during ${order.deliverySlot.toUpperCase()} slot ($slotTimingText).",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Skip options
                if (order.frequency != 'one-time') ...[
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: (isTargetSkipped || (!isTargetSkipped && hasReachedSkipLimit)) 
                          ? AppTheme.textMuted 
                          : AppTheme.secondaryMarigold,
                      side: BorderSide(
                        color: (isTargetSkipped || (!isTargetSkipped && hasReachedSkipLimit)) 
                            ? AppTheme.borderLight 
                            : AppTheme.secondaryMarigold,
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      minimumSize: const Size(double.infinity, 44),
                      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    icon: Icon(
                      isTargetSkipped 
                          ? Icons.check_circle_outline 
                          : (hasReachedSkipLimit ? Icons.lock_outline : Icons.skip_next_outlined),
                      size: 16,
                    ),
                    label: Text(
                      isTargetSkipped 
                          ? "Delivery Skipped" 
                          : (hasReachedSkipLimit ? "Weekly Skip Limit Reached" : "Skip $dayLabel's Delivery"),
                    ),
                    onPressed: (isTargetSkipped || hasReachedSkipLimit)
                        ? null
                        : () {
                            context.read<OrdersCubit>().skipDeliveryDate(order.id, targetSkipDate);
                            NotificationOverlay.show(
                              context,
                              title: "Delivery Skipped",
                              message: "Your delivery has been skipped for $dayLabel.",
                              icon: Icons.skip_next,
                            );
                          },
                  ),
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      "Note: Skip requests accepted up to 2 hours before delivery ($cutoffText cutoff)",
                      style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildHistoryList(List<OrderModel> orderHistory) {
    if (orderHistory.isEmpty) {
      return _buildEmptyState("No one-time orders found", "Order a single-day fresh meal to try Atithi Bhoj!");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SubscriptionDetailsScreen(order: order),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.015),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Calendar/History Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: order.orderStatus == 'cancelled'
                      ? AppTheme.errorColor.withOpacity(0.06)
                      : AppTheme.primaryGreen.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  order.orderStatus == 'cancelled' 
                      ? Icons.cancel_outlined 
                      : Icons.assignment_turned_in_outlined,
                  size: 20,
                  color: order.orderStatus == 'cancelled' ? AppTheme.errorColor : AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(width: 16),
              
              // Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Order #${order.id.toUpperCase().substring(order.id.length - 6)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${order.frequency.toUpperCase()} plan • ${order.quantity} box • $formattedDate",
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              
              // Price and status badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "₹${order.finalAmount.toStringAsFixed(0)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.orderStatus == 'cancelled' ? "Cancelled" : "Completed",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: order.orderStatus == 'cancelled' ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
      },
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 64, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
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
}
