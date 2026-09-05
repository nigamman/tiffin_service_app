import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/admin_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';

class AdminOrderList extends StatefulWidget {
  const AdminOrderList({Key? key}) : super(key: key);

  @override
  State<AdminOrderList> createState() => _AdminOrderListState();
}

class _AdminOrderListState extends State<AdminOrderList> {
  final OrdersRepository _ordersRepository = OrdersRepository();
  bool _isLoading = true;
  List<OrderModel> _orders = [];
  Map<String, Map<String, String>> _userProfiles = {};
  String? _error;
  String _filter = 'all'; // 'all', 'today', 'tomorrow'

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _ordersRepository.adminGetAllOrders();
      
      // Fetch user profiles for address fallback on legacy orders
      final usersList = await FirebaseService.instance.collectionGet('users');
      final Map<String, Map<String, String>> profileMap = {};
      for (final u in usersList) {
        final phone = (u['phone'] ?? '').toString();
        final id = (u['id'] ?? '').toString();
        final Map<String, String> addr = {
          'houseNo': (u['houseNo'] ?? '').toString(),
          'area': (u['area'] ?? '').toString(),
          'landmark': (u['landmark'] ?? '').toString(),
        };
        if (phone.isNotEmpty) profileMap[phone] = addr;
        if (id.isNotEmpty) profileMap[id] = addr;
      }

      setState(() {
        _orders = list;
        _userProfiles = profileMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  String _getDeliveryAddress(OrderModel order) {
    String houseNo = order.houseNo;
    String area = order.area;
    String landmark = order.landmark;

    if (houseNo.isEmpty && area.isEmpty) {
      final profile = _userProfiles[order.contactPhone];
      if (profile != null) {
        houseNo = profile['houseNo'] ?? '';
        area = profile['area'] ?? '';
        landmark = profile['landmark'] ?? '';
      }
    }

    final parts = [houseNo, area, landmark].where((s) => s.isNotEmpty).toList();
    if (parts.isNotEmpty) {
      return parts.join(', ');
    }
    return "Address not specified (Kalyanpur Zone)";
  }

  void _cancelOrder(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text("Are you sure you want to cancel this customer subscription?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Close")),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Cancel Subscription"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _ordersRepository.adminUpdateStatus(id, 'cancelled');
        _loadOrders();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Subscription cancelled successfully")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to cancel: $e"), backgroundColor: AppTheme.errorColor),
          );
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _updateTodayStatus(String orderId, String status) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _ordersRepository.adminUpdateTodayDeliveryStatus(orderId, status, todayStr);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Today's delivery status updated to: ${status.toUpperCase().replaceAll('_', ' ')}"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update status: $e"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _updateOutForDelivery() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      await _ordersRepository.adminUpdateAllTodayDeliveryStatus('out_for_delivery', todayStr);
      await _loadOrders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("All today's active deliveries marked as OUT FOR DELIVERY"),
            backgroundColor: AppTheme.primaryGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update status: $e"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildStatusButton(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    Color activeColor = AppTheme.primaryGreen;
    if (label == 'Delivered') activeColor = AppTheme.successColor;
    if (label == 'Out for Delivery') activeColor = AppTheme.secondaryMarigold;

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: isSelected ? Colors.white : activeColor,
        backgroundColor: isSelected ? activeColor : Colors.white,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(color: activeColor, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 10),
      ),
      onPressed: onTap,
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Apply filters locally for robust mock support
    final List<OrderModel> filteredOrders = _orders.where((o) {
      if (_filter == 'all') return true;
      
      final today = DateTime.now();
      final target = _filter == 'today' ? today : today.add(const Duration(days: 1));
      final targetNormalized = DateTime(target.year, target.month, target.day);

      if (o.frequency == 'one-time') {
        final start = DateTime(o.startDate.year, o.startDate.month, o.startDate.day);
        return start.isAtSameMomentAs(targetNormalized);
      } else {
        // Recurring plans are active if start date is on or before target date and order is not cancelled
        if (o.orderStatus == 'cancelled') return false;
        
        final startNormalized = DateTime(o.startDate.year, o.startDate.month, o.startDate.day);
        final startsOnOrBefore = startNormalized.isBefore(targetNormalized) || startNormalized.isAtSameMomentAs(targetNormalized);
        
        // Also check if they skipped this specific date
        final isDateSkipped = o.skippedDates.any(
          (d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(targetNormalized),
        );

        return startsOnOrBefore && !isDateSkipped;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Manage Incoming Orders"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildFilterButton("All Orders", "all"),
                _buildFilterButton("Today's Deliveries", "today"),
                _buildFilterButton("Tomorrow's", "tomorrow"),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderLight),

          // Orders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Error: $_error"),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _loadOrders, child: const Text("Retry")),
                          ],
                        ),
                      )
                    : filteredOrders.isEmpty
                        ? const Center(
                            child: Text(
                              "No matching orders found.",
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16.0),
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              final startDateFormatted = DateFormat('dd MMM yyyy').format(order.startDate);

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
                                          Text(
                                            "Order #${order.id.toUpperCase().substring(order.id.length - 6)}",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                                                color: order.orderStatus == 'cancelled'
                                                    ? AppTheme.errorColor
                                                    : AppTheme.successColor,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Plan: ${order.frequency.toUpperCase()} plan (x${order.quantity} box)",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                      ),
                                      const SizedBox(height: 4),
                                      Text("Deliver Phone: +91 ${order.contactPhone}", style: const TextStyle(fontSize: 13)),
                                      const SizedBox(height: 2),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.primaryGreen),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              "Address: ${_getDeliveryAddress(order)}",
                                              style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w500),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text("Start date: $startDateFormatted • Slot: ${order.deliverySlot.toUpperCase()}", style: const TextStyle(fontSize: 13)),
                                      Text("Skips: ${order.skippedDates.length} meals skipped", style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                                      if (order.frequency != 'one-time') ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          "Tiffins: ${order.deliveredMeals} Got • ${order.remainingMeals} Left (of ${order.totalMeals} total)",
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                        ),
                                      ],
                                      if (order.isScheduledToday) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Text("Today's Tiffin: ", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
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
                                      ],
                                      // Today's delivery status management card
                                      if (order.orderStatus != 'cancelled' && order.isScheduledToday) ...[
                                        const Divider(height: 20, color: AppTheme.borderLight),
                                        Text(
                                          "Manage Today's Food Delivery",
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: AppTheme.primaryGreen,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildStatusButton(
                                                context,
                                                label: 'Out for Delivery',
                                                isSelected: order.todayDeliveryStatusDate == DateFormat('yyyy-MM-dd').format(DateTime.now()) && order.todayDeliveryStatus == 'out_for_delivery',
                                                onTap: () => _updateOutForDelivery(),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _buildStatusButton(
                                                context,
                                                label: 'Delivered',
                                                isSelected: order.todayDeliveryStatusDate == DateFormat('yyyy-MM-dd').format(DateTime.now()) && order.todayDeliveryStatus == 'delivered',
                                                onTap: () => _updateTodayStatus(order.id, 'delivered'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const Divider(height: 20, color: AppTheme.borderLight),
                                      
                                      // Cancel action button
                                      if (order.orderStatus != 'cancelled')
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                                            icon: const Icon(Icons.cancel_outlined, size: 16),
                                            label: const Text("Cancel Subscription"),
                                            onPressed: () => _cancelOrder(order.id),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _filter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filter = value;
          });
        }
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.primaryGreen, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }
}
