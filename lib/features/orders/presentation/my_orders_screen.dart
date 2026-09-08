import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/notification_overlay.dart';
import 'order_details_screen.dart';
import 'subscription_details_screen.dart';
import '../../../core/services/invoice_service.dart';
import '../../auth/presentation/auth_cubit.dart';


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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "My Bookings",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textMuted,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 2.5,
          labelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 13.5,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.w500,
            fontSize: 13.5,
          ),
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

          final bool isTodayScheduled = order.isScheduledToday;

          final bool isTomorrowScheduled = order.orderStatus != 'cancelled' &&
              !DateTime(order.startDate.year, order.startDate.month, order.startDate.day).isAfter(tomorrowNormalized) &&
              (order.frequency == 'one-time'
                  ? DateTime(order.startDate.year, order.startDate.month, order.startDate.day).isAtSameMomentAs(tomorrowNormalized)
                  : OrderModel.isDeliveryDay(tomorrowNormalized, order.frequency));

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => order.frequency != 'one-time'
                      ? SubscriptionDetailsScreen(order: order)
                      : OrderDetailsScreen(order: order),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 12,
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${order.frequency.toUpperCase()} PLAN",
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        "Order #${order.id.substring(0, order.id.length > 8 ? 8 : order.id.length)}",
                        style: GoogleFonts.poppins(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Home Tiffin Meal  •  ${order.quantity} Box (${order.deliverySlot.toUpperCase()})",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Started: ${DateFormat('dd MMM yyyy').format(order.startDate)}",
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  if (order.frequency != 'one-time') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Delivered: ${order.deliveredMeals} Got  •  Remaining: ${order.remainingMeals} Left",
                          style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          "${(order.progressPercent * 100).toStringAsFixed(0)}%",
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: order.progressPercent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  
                  // Today/Tomorrow Delivery Status Row
                  if (isTodayScheduled) ...[
                    Row(
                      children: [
                        Icon(
                          order.todayActiveStage == 3 ? Icons.check_circle : Icons.pedal_bike,
                          size: 18,
                          color: order.todayActiveStage == 3 ? AppTheme.successColor : AppTheme.secondaryMarigold,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          "Today's Delivery: ",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        Text(
                          order.todayStatusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: order.todayActiveStage == 3
                                ? AppTheme.successColor
                                : (order.todayActiveStage == 2
                                    ? AppTheme.secondaryMarigold
                                    : (order.todayActiveStage == 1
                                        ? Colors.orange
                                        : AppTheme.textDark)),
                          ),
                        ),
                      ],
                    ),
                  ] else if (isTomorrowScheduled) ...[
                    const Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 18,
                          color: AppTheme.primaryGreen,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Tomorrow's Delivery: ",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                        ),
                        Text(
                          "SCHEDULED",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.successColor,
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
                  if (order.frequency != 'one-time') ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Tap to view delivery log & schedule",
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppTheme.primaryGreen),
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
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.primaryGreen, size: 22),
                  tooltip: "Download PDF Invoice",
                  onPressed: () {
                    final authState = context.read<AuthCubit>().state;
                    final user = authState is AuthAuthenticated ? authState.user : null;
                    InvoiceService.downloadOrPrintInvoice(context, order, user: user);
                  },
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
