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
          
          // Calculate remaining meals
          final totalMeals = order.mealsCount;
          final skippedCount = order.skippedDates.length;
          // In a real app, you would subtract completed deliveries too.
          // For MVP, we show remaining meals = total - skipped.
          final remainingMeals = (totalMeals - skippedCount).clamp(0, totalMeals);

          // Check if tomorrow is skipped
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final tomorrowNormalized = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
          final isTomorrowSkipped = order.skippedDates.any(
            (d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(tomorrowNormalized),
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          "${order.frequency.toUpperCase()} PLAN",
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.circle, color: AppTheme.successColor, size: 10),
                          SizedBox(width: 6),
                          Text(
                            "Confirmed",
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
                  const SizedBox(height: 12),
                  Text(
                    "Home Tiffin Meal x ${order.quantity}",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Remaining meals: $remainingMeals / $totalMeals",
                    style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                  const Divider(height: 24, color: AppTheme.borderLight),
                  
                  // Next delivery slot info
                  Row(
                    children: [
                      const Icon(Icons.delivery_dining, size: 20, color: AppTheme.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isTomorrowSkipped
                              ? "Next delivery: Skipped for tomorrow ❌"
                              : "Next delivery: Tomorrow • ${order.deliverySlot.toUpperCase()}",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isTomorrowSkipped ? AppTheme.errorColor : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Skip tomorrow option (Only for daily, weekly, monthly subscription models)
                  if (order.frequency != 'one-time') ...[
                    const SizedBox(height: 16),
                    if (isTomorrowSkipped)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            "Tomorrow's meal delivery skipped",
                            style: TextStyle(color: AppTheme.errorColor, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ),
                      )
                    else
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.secondaryMarigold,
                          side: const BorderSide(color: AppTheme.secondaryMarigold, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                        icon: const Icon(Icons.skip_next, size: 18),
                        label: const Text("Skip Tomorrow's Delivery"),
                        onPressed: () {
                          // Skip date
                          context.read<OrdersCubit>().skipDeliveryDate(order.id, tomorrowNormalized);
                          NotificationOverlay.show(
                            context,
                            title: "Delivery Skipped",
                            message: "Your tiffin delivery is skipped for tomorrow.",
                            icon: Icons.skip_next,
                          );
                        },
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
      return _buildEmptyState("No order history found", "Complete a tiffin subscription to see records here!");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: orderHistory.length,
      itemBuilder: (context, index) {
        final order = orderHistory[index];
        final formattedDate = DateFormat('dd MMM yyyy').format(order.createdAt);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Order #${order.id.toUpperCase().substring(order.id.length - 6)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit'),
                ),
                Text(
                  "₹${order.finalAmount.toStringAsFixed(0)}",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontFamily: 'Outfit'),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  "${order.frequency.toUpperCase()} plan • ${order.quantity} box • $formattedDate",
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  order.orderStatus == 'cancelled' ? "🔴 Cancelled" : "🟢 Completed",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: order.orderStatus == 'cancelled' ? AppTheme.errorColor : AppTheme.successColor,
                  ),
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
