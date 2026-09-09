import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import 'subscription_details_screen.dart';
import '../../../core/services/invoice_service.dart';
import '../../auth/presentation/auth_cubit.dart';

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
  void _openWhatsAppSupport(BuildContext context, OrderModel order, String issueTitle) async {
    final orderShortId = order.id.length > 6 
        ? order.id.toUpperCase().substring(order.id.length - 6) 
        : order.id.toUpperCase();
    final message = "Hi Atithi Bhoj Support, I need assistance with Order #$orderShortId (${order.frequency.toUpperCase()} plan, ${order.deliverySlot.toUpperCase()} slot).\n\n"
        "Issue: $issueTitle\n"
        "Contact Phone: +91 ${order.contactPhone}\n"
        "Delivery Address: ${order.houseNo}, ${order.area}";

    final url = "https://wa.me/919119724875?text=${Uri.encodeComponent(message)}";
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch WhatsApp. Please contact +91 9119724875 directly.")),
        );
      }
    }
  }

  void _showWhatsAppSupportModal(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.support_agent, color: Colors.green.shade700, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "1-Tap WhatsApp Support",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppTheme.textDark,
                          ),
                        ),
                        Text(
                          "Select issue for Order #${order.id.toUpperCase().substring(order.id.length - 6)}",
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSupportOptionTile(
                ctx,
                icon: Icons.delivery_dining,
                title: "Meal Not Received Today",
                subtitle: "Marked delivered or past delivery time slot",
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsAppSupport(context, order, "Meal Not Received Today");
                },
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildSupportOptionTile(
                ctx,
                icon: Icons.soup_kitchen_outlined,
                title: "Packaging or Spilled Tiffin",
                subtitle: "Damaged container or quality feedback",
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsAppSupport(context, order, "Packaging or Quality Issue");
                },
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildSupportOptionTile(
                ctx,
                icon: Icons.access_time,
                title: "Delivery Time & ETA Inquiry",
                subtitle: "Check expected arrival time for today's slot",
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsAppSupport(context, order, "Delivery Time Inquiry");
                },
              ),
              Divider(height: 1, color: Colors.grey.shade100),
              _buildSupportOptionTile(
                ctx,
                icon: Icons.chat_bubble_outline,
                title: "General Order Assistance",
                subtitle: "Address change, payment, or custom question",
                onTap: () {
                  Navigator.pop(ctx);
                  _openWhatsAppSupport(context, order, "General Order Query");
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSupportOptionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 18),
      onTap: onTap,
    );
  }
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

          final bool isTodayScheduled = order.isScheduledToday;

          final bool isTomorrowScheduled = order.orderStatus != 'cancelled' &&
              !DateTime(order.startDate.year, order.startDate.month, order.startDate.day).isAfter(tomorrowNormalized) &&
              (order.frequency == 'one-time'
                  ? DateTime(order.startDate.year, order.startDate.month, order.startDate.day).isAtSameMomentAs(tomorrowNormalized)
                  : OrderModel.isDeliveryDay(tomorrowNormalized, order.frequency));

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
                         if (order.deliveryInstructions.isNotEmpty)
                          _buildInfoRow(Icons.note_alt_outlined, "Instructions", order.deliveryInstructions),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                            label: Text(
                              "Download PDF Invoice",
                              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              final authState = context.read<AuthCubit>().state;
                              final user = authState is AuthAuthenticated ? authState.user : null;
                              InvoiceService.downloadOrPrintInvoice(context, order, user: user);
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.green.shade700,
                              side: BorderSide(color: Colors.green.shade600, width: 1.2),
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: Colors.green.shade50.withOpacity(0.4),
                            ),
                            icon: const Icon(Icons.chat, size: 18, color: Color(0xFF25D366)),
                            label: Text(
                              "Need Help? Contact WhatsApp Support",
                              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => _showWhatsAppSupportModal(context, order),
                          ),
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
                            "Track Today's $activeSlotName Delivery",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Delivery window: $timeRange",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: const Color(0xFFC3A575),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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
                          const Icon(
                            Icons.calendar_today_outlined,
                            color: AppTheme.primaryGreen,
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
                                const Text(
                                  "SCHEDULED (Lunch: 11:30 AM / Dinner: 7:00 PM)",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.successColor,
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
                            "Tiffin Meals Counter",
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
                                "Delivered Tiffins",
                                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              Text(
                                "${order.deliveredMeals} Got",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
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
                                "Remaining Tiffins",
                                style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                              ),
                              Text(
                                "${order.remainingMeals} Left",
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.secondaryMarigold,
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
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              minimumSize: const Size(double.infinity, 44),
                              elevation: 0,
                              textStyle: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                            icon: const Icon(Icons.calendar_month_outlined, size: 16),
                            label: const Text("View Full Delivery Schedule & Log"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SubscriptionDetailsScreen(order: order),
                                ),
                              );
                            },
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
