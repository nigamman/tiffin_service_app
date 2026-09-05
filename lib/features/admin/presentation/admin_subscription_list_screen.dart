import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';
import '../../orders/data/orders_repository.dart';

class AdminSubscriptionListScreen extends StatefulWidget {
  const AdminSubscriptionListScreen({Key? key}) : super(key: key);

  @override
  State<AdminSubscriptionListScreen> createState() => _AdminSubscriptionListScreenState();
}

class _AdminSubscriptionListScreenState extends State<AdminSubscriptionListScreen> {
  final OrdersRepository _ordersRepository = OrdersRepository();
  final FirebaseService _db = FirebaseService.instance;

  bool _isLoading = true;
  String? _error;
  
  List<OrderModel> _subscriptions = [];
  Map<String, String> _userNames = {}; // Map phone -> user name or user id -> name
  Map<String, String> _userAddresses = {}; // Map phone/id -> user address

  String _searchQuery = '';
  String _filter = 'active'; // 'active', 'completed_cancelled', 'all'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // 1. Load all paid subscriptions/orders
      final allOrders = await _ordersRepository.adminGetAllOrders();
      // Filter out non-recurring ones if needed, but we keep recurring ones since those are subscriptions
      final recurringOnly = allOrders.where((o) => o.frequency != 'one-time').toList();

      // 2. Load users to match names and addresses
      final usersList = await _db.collectionGet('users');
      final Map<String, String> nameMap = {};
      final Map<String, String> addrMap = {};
      for (final u in usersList) {
        final phone = u['phone'] ?? '';
        final name = u['name'] ?? '';
        final id = u['id'] ?? '';
        
        final houseNo = u['houseNo'] ?? '';
        final area = u['area'] ?? '';
        final landmark = u['landmark'] ?? '';
        final fullAddr = [houseNo, area, landmark].where((s) => (s as String).isNotEmpty).join(', ');

        if (phone.isNotEmpty) {
          if (name.isNotEmpty) nameMap[phone] = name;
          if (fullAddr.isNotEmpty) addrMap[phone] = fullAddr;
        }
        if (id.isNotEmpty) {
          if (name.isNotEmpty) nameMap[id] = name;
          if (fullAddr.isNotEmpty) addrMap[id] = fullAddr;
        }
      }

      setState(() {
        _subscriptions = recurringOnly;
        _userNames = nameMap;
        _userAddresses = addrMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Filter and search logic
    final List<OrderModel> filteredList = _subscriptions.where((sub) {
      // 1. Search Query Filter
      final userName = (_userNames[sub.contactPhone] ?? 'Customer').toLowerCase();
      final phone = sub.contactPhone.toLowerCase();
      final planName = sub.frequency.toLowerCase();
      final id = sub.id.toLowerCase();
      
      final matchesSearch = userName.contains(_searchQuery.toLowerCase()) ||
          phone.contains(_searchQuery.toLowerCase()) ||
          planName.contains(_searchQuery.toLowerCase()) ||
          id.contains(_searchQuery.toLowerCase());
          
      if (!matchesSearch) return false;

      // 2. Tab/Status Filter
      final isCancelled = sub.orderStatus == 'cancelled';
      final isCompleted = sub.remainingMeals == 0;
      final isActive = !isCancelled && !isCompleted;

      if (_filter == 'active') {
        return isActive;
      } else if (_filter == 'completed_cancelled') {
        return isCompleted || isCancelled;
      }
      return true; // 'all'
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          "Subscriber Tiffin Log",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.primaryGreen),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Error loading data: $_error", textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadData, child: const Text("Retry")),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      key: const ValueKey('search_bar_container'),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search by subscriber name, phone or plan...",
                          prefixIcon: const Icon(Icons.search, color: AppTheme.textMuted),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 1.5),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),
                    ),

                    // Filter Row
                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      key: const ValueKey('filter_row_container'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildFilterButton("Active Subscriptions", "active"),
                          _buildFilterButton("Ended / Cancelled", "completed_cancelled"),
                          _buildFilterButton("All Plans", "all"),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),

                    // Subscription List
                    Expanded(
                      child: filteredList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: AppTheme.textMuted.withOpacity(0.5)),
                                  const SizedBox(height: 12),
                                  Text(
                                    "No matching subscribers found",
                                    style: GoogleFonts.poppins(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: filteredList.length,
                              itemBuilder: (context, index) {
                                final sub = filteredList[index];
                                final name = _userNames[sub.contactPhone] ?? 'Customer';
                                return _buildSubscriptionCard(sub, name);
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
          fontSize: 11,
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

  Widget _buildSubscriptionCard(OrderModel sub, String userName) {
    final startFormatted = DateFormat('dd MMM yyyy').format(sub.startDate);
    final daysElapsed = DateTime.now().difference(sub.startDate).inDays;
    
    // Status indicators
    final isCancelled = sub.orderStatus == 'cancelled';
    final isCompleted = sub.remainingMeals == 0;
    
    Color statusBgColor = AppTheme.successColor.withOpacity(0.08);
    Color statusTextColor = AppTheme.successColor;
    String statusLabel = "ACTIVE";

    if (isCancelled) {
      statusBgColor = AppTheme.errorColor.withOpacity(0.08);
      statusTextColor = AppTheme.errorColor;
      statusLabel = "CANCELLED";
    } else if (isCompleted) {
      statusBgColor = Colors.grey.withOpacity(0.12);
      statusTextColor = AppTheme.textMuted;
      statusLabel = "COMPLETED";
    }

    final double progress = sub.totalMeals > 0 ? sub.deliveredMeals / sub.totalMeals : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.05),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "+91 ${sub.contactPhone}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      sub.frequency == 'monthly' ? Icons.calendar_month : Icons.calendar_view_week,
                      size: 13,
                      color: AppTheme.primaryGreen,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "${sub.frequency.toUpperCase()} PLAN (${sub.deliverySlot.toUpperCase()})",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Tiffins got: ${sub.deliveredMeals}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: AppTheme.textDark,
                      ),
                    ),
                    Text(
                      "Left: ${sub.remainingMeals} / ${sub.totalMeals}",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: isCompleted ? AppTheme.textMuted : AppTheme.secondaryMarigold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isCompleted
                          ? Colors.grey
                          : (progress > 0.85 ? AppTheme.successColor : AppTheme.primaryGreen),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppTheme.borderLight, height: 16),
                  
                  // Detailed Information Row
                  _buildDetailRow(Icons.date_range_outlined, "Start Date", startFormatted),
                  _buildDetailRow(Icons.timelapse_outlined, "Days Active", daysElapsed < 0 ? "Not started yet" : "$daysElapsed days"),
                  _buildDetailRow(Icons.layers_outlined, "Quantity", "x${sub.quantity} box(es) per slot"),
                  _buildDetailRow(Icons.currency_rupee, "Price Paid", "₹${sub.finalAmount.toStringAsFixed(2)}"),
                  _buildDetailRow(
                    Icons.location_on_outlined,
                    "Delivery Address",
                    () {
                      final orderParts = [sub.houseNo, sub.area, sub.landmark].where((s) => s.isNotEmpty).join(', ');
                      if (orderParts.isNotEmpty) return orderParts;
                      final userAddr = _userAddresses[sub.contactPhone];
                      if (userAddr != null && userAddr.isNotEmpty) return userAddr;
                      return "Address not specified (Kalyanpur Zone)";
                    }(),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Skips Summary Section
                  Text(
                    "Delivery Skip Logs:",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  sub.skippedDates.isEmpty && sub.skippedSlots.isEmpty
                      ? const Text(
                          "No meals skipped yet.",
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sub.skippedDates.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: sub.skippedDates.map((date) {
                                  return Chip(
                                    label: Text(
                                      DateFormat('dd MMM').format(date),
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.errorColor),
                                    ),
                                    backgroundColor: AppTheme.errorColor.withOpacity(0.06),
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                            if (sub.skippedSlots.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              const Text(
                                "Slot level skips:",
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: sub.skippedSlots.map((slotKey) {
                                  final split = slotKey.split('_');
                                  String label = slotKey;
                                  try {
                                    final date = DateTime.parse(split[0]);
                                    final formattedDate = DateFormat('dd MMM').format(date);
                                    label = "$formattedDate (${split[1].toUpperCase()})";
                                  } catch (_) {}
                                  return Chip(
                                    label: Text(
                                      label,
                                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: AppTheme.textMuted),
                                    ),
                                    backgroundColor: AppTheme.backgroundLight,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ]
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(
            "$label: ",
            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, color: AppTheme.textDark, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
