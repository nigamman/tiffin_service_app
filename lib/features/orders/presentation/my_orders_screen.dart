import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/notification_overlay.dart';
import 'order_details_screen.dart';


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
            Tab(text: "Active Bookings"),
            Tab(text: "Order History"),
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
      return _buildEmptyState("No active bookings found", "Order a single-day meal or subscribe to a plan today!");
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

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(order: order),
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
                  const SizedBox(height: 6),
                  Text(
                    "Delivery Slot: ${order.deliverySlot.toUpperCase()}",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const Divider(height: 24, color: AppTheme.borderLight),
                  
                  // Scheduled Status
                  if (isTodayScheduled) ...[
                    Row(
                      children: [
                        Icon(
                          isTodaySkipped 
                              ? Icons.block_outlined 
                              : (order.todayActiveStage == 3 ? Icons.check_circle : Icons.pedal_bike),
                          size: 18,
                          color: isTodaySkipped 
                              ? AppTheme.errorColor 
                              : (order.todayActiveStage == 3 ? AppTheme.successColor : AppTheme.secondaryMarigold),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Today's Delivery: ",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        Text(
                          isTodaySkipped ? "SKIPPED" : order.todayStatusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isTodaySkipped
                                ? AppTheme.errorColor
                                : (order.todayActiveStage == 3
                                    ? AppTheme.successColor
                                    : (order.todayActiveStage == 2
                                        ? AppTheme.secondaryMarigold
                                        : (order.todayActiveStage == 1
                                            ? Colors.orange
                                            : AppTheme.textDark))),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isTomorrowScheduled) ...[
                    Row(
                      children: [
                        Icon(
                          isTomorrowSkipped ? Icons.block_outlined : Icons.calendar_today_outlined,
                          size: 18,
                          color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Tomorrow's Delivery: ",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        Text(
                          isTomorrowSkipped ? "SKIPPED" : "SCHEDULED",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.successColor,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Scheduled for: ${DateFormat('dd MMM').format(order.startDate)}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ],
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
      return _buildEmptyState("No order history found", "Your completed or cancelled bookings will appear here.");
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
                builder: (context) => OrderDetailsScreen(order: order),
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
                      order.orderStatus == 'cancelled' ? "Cancelled" : "Delivered",
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
}
