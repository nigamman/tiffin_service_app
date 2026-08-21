import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/notification_overlay.dart';


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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Outfit'),
          tabs: const [
            Tab(text: "Active Plans"),
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
      return _buildEmptyState("No active plans found", "Order today's fresh tiffin to start a plan!");
    }

    return RefreshIndicator(
      onRefresh: () => context.read<OrdersCubit>().loadOrders(),
      color: AppTheme.primaryGreen,
      child: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: activeOrders.length,
        itemBuilder: (context, index) {
          final order = activeOrders[index];
          
          final totalMeals = order.mealsCount;
          final skippedCount = order.skippedDates.length;
          final remainingMeals = (totalMeals - skippedCount).clamp(0, totalMeals);

          // Calculate percentage for thin progress indicator
          final double progressPercent = totalMeals > 0 ? remainingMeals / totalMeals : 0;

          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final tomorrowNormalized = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
          final isTomorrowSkipped = order.skippedDates.any(
            (d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(tomorrowNormalized),
          );

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderLight, width: 0.8),
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
                        color: AppTheme.primaryGreen.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "${order.frequency.toUpperCase()} PLAN",
                        style: const TextStyle(
                          color: AppTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontFamily: 'Outfit',
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
                            fontFamily: 'Outfit',
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
                    fontFamily: 'Outfit',
                  ),
                ),
                const SizedBox(height: 12),

                // Premium Progress Tracker
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Subscription Progress",
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'PlusJakartaSans'),
                    ),
                    Text(
                      "$remainingMeals of $totalMeals meals left",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontFamily: 'Outfit'),
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
                
                // Timeline Delivery details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isTomorrowSkipped 
                            ? AppTheme.errorColor.withOpacity(0.06)
                            : AppTheme.primaryGreen.withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isTomorrowSkipped ? Icons.block_outlined : Icons.delivery_dining_outlined,
                        size: 18,
                        color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isTomorrowSkipped
                                ? "Tomorrow's Delivery Skipped"
                                : "Scheduled Tomorrow",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.textDark,
                              fontFamily: 'Outfit',
                            ),
                          ),
                          Text(
                            isTomorrowSkipped
                                ? "You will not receive tiffin box for tomorrow's ${order.deliverySlot} slot."
                                : "Delivered tomorrow during ${order.deliverySlot.toUpperCase()} slot (12-2 PM).",
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                              height: 1.3,
                              fontFamily: 'PlusJakartaSans',
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
                  if (!isTomorrowSkipped)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.secondaryMarigold,
                        side: const BorderSide(color: AppTheme.secondaryMarigold, width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(double.infinity, 44),
                        textStyle: const TextStyle(fontFamily: 'Outfit', fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      icon: const Icon(Icons.skip_next_outlined, size: 16),
                      label: const Text("Skip Tomorrow's Delivery"),
                      onPressed: () {
                        context.read<OrdersCubit>().skipDeliveryDate(order.id, tomorrowNormalized);
                        NotificationOverlay.show(
                          context,
                          title: "Delivery Skipped",
                          message: "Your tiffin delivery has been skipped for tomorrow.",
                          icon: Icons.skip_next,
                        );
                      },
                    ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHistoryList(List<OrderModel> orderHistory) {
    if (orderHistory.isEmpty) {
      return _buildEmptyState("No order history found", "Complete a tiffin subscription to see records here!");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderLight, width: 0.8),
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
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      "${order.frequency.toUpperCase()} plan • ${order.quantity} box • $formattedDate",
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'PlusJakartaSans'),
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
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    order.orderStatus == 'cancelled' ? "Cancelled" : "Completed",
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: order.orderStatus == 'cancelled' ? AppTheme.errorColor : AppTheme.successColor,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ],
              ),
            ],
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark, fontFamily: 'Outfit'),
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
