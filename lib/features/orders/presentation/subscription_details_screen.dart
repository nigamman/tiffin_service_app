import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'orders_cubit.dart';
import '../data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/notification_overlay.dart';
import 'package:google_fonts/google_fonts.dart';
import 'order_details_screen.dart';
import '../../../core/services/invoice_service.dart';
import '../../auth/presentation/auth_cubit.dart';

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
  bool _showAllSchedule = false;

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

    // List of all delivery days in the subscription plan (from startDate)
    final List<DateTime> allPlanDays = [];
    final startNormalized = DateTime(order.startDate.year, order.startDate.month, order.startDate.day);
    DateTime checkDate = startNormalized;
    
    int totalSlotsCollected = 0;
    int safetyLimit = 60; // safety ceiling

    while (totalSlotsCollected < totalMeals && safetyLimit > 0) {
      if (_isDeliveryDay(checkDate, order.frequency)) {
        allPlanDays.add(checkDate);
        totalSlotsCollected += (order.deliverySlot == 'both' ? 2 : 1);
      }
      checkDate = checkDate.add(const Duration(days: 1));
      safetyLimit--;
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
            // 2. Complete Delivery Schedule & History Log
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Delivery Schedule & Log",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    "${order.deliveredMeals} of $totalMeals Delivered",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                ],
              ),
            ),

            _buildSevenDayScheduleList(context, order, allPlanDays),
          ],

          // 3. Billing & Address section
          _buildBillingDetailsCard(context, order),
          
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
                  "Delivered: ${order.deliveredMeals} Got  •  Remaining: ${order.remainingMeals} Left",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "${(order.progressPercent * 100).toStringAsFixed(0)}% Consumed",
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
          const SizedBox(height: 16),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryGreen,
              side: const BorderSide(color: AppTheme.primaryGreen, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              minimumSize: const Size(double.infinity, 42),
            ),
            icon: const Icon(Icons.pedal_bike, size: 16),
            label: Text(
              "Track Today's Live Delivery Status",
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsScreen(order: order),
                ),
              );
            },
          ),
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

  Widget _buildSevenDayScheduleList(BuildContext context, OrderModel order, List<DateTime> nextDays) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final displayedDays = _showAllSchedule ? nextDays : nextDays.take(3).toList();

    return Column(
      children: [
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: displayedDays.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final dayDate = displayedDays[index];
            final dayName = DateFormat('EEEE').format(dayDate);
            final dateLabel = DateFormat('dd MMM').format(dayDate);
            
            final isToday = dayDate.isAtSameMomentAs(today);

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
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Dynamic slots list for this day
                  ...activeSlots.map((slot) {
                    final deliveryStart = slot == 'lunch' ? "11:30 AM" : "7:00 PM";
                    final isDelivered = order.isSlotDelivered(dayDate, slot);

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
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                Text(
                                  "Starts at $deliveryStart",
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Status icon/badge
                          Row(
                            children: [
                              Icon(
                                isDelivered ? Icons.check_circle_outline : Icons.schedule,
                                size: 14,
                                color: isDelivered ? AppTheme.successColor : AppTheme.textMuted,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDelivered ? "Delivered" : "Scheduled",
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDelivered ? AppTheme.successColor : AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            );
          },
        ),
        if (nextDays.length > 3) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.4), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                minimumSize: const Size(double.infinity, 44),
                backgroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showAllSchedule = !_showAllSchedule;
                });
              },
              icon: Icon(
                _showAllSchedule ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 20,
              ),
              label: Text(
                _showAllSchedule
                    ? "Show Less"
                    : "View Full Schedule (${nextDays.length - 3} More Days)",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBillingDetailsCard(BuildContext context, OrderModel order) {
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
          if (order.deliveryInstructions.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildBillingRow("Instructions", order.deliveryInstructions),
          ],
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
                padding: const EdgeInsets.symmetric(vertical: 12),
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
