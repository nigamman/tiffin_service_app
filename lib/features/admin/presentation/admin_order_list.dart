import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/admin_repository.dart';
import '../../orders/data/orders_repository.dart';
import '../../../core/theme/app_theme.dart';

class AdminOrderList extends StatefulWidget {
  const AdminOrderList({Key? key}) : super(key: key);

  @override
  State<AdminOrderList> createState() => _AdminOrderListState();
}

class _AdminOrderListState extends State<AdminOrderList> {
  final OrdersRepository _ordersRepository = OrdersRepository();
  bool _isLoading = true;
  List<OrderModel> _orders = [];
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
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
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
                                      Text("Start date: $startDateFormatted • Slot: ${order.deliverySlot.toUpperCase()}", style: const TextStyle(fontSize: 13)),
                                      Text("Skips: ${order.skippedDates.length} meals skipped", style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
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
