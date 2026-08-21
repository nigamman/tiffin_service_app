import 'package:flutter/material.dart';
import '../data/admin_repository.dart';
import 'admin_menu_management.dart';
import 'admin_coupon_management.dart';
import 'admin_order_list.dart';
import '../../../core/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminRepository _repository = AdminRepository();
  bool _isLoading = true;
  AdminAnalyticsModel? _analytics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.getDashboardAnalytics();
      setState(() {
        _analytics = data;
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
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Admin Control Console"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
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
                        Text("Error loading analytics: $_error", textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(onPressed: _loadAnalytics, child: const Text("Retry")),
                      ],
                    ),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Business Analytics",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),

                      // Metrics Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.35,
                        children: [
                          _buildMetricCard(
                            context,
                            title: "Today's Orders",
                            value: "${_analytics?.todayOrdersCount}",
                            icon: Icons.shopping_bag,
                            color: AppTheme.primaryGreen,
                          ),
                          _buildMetricCard(
                            context,
                            title: "Today's Revenue",
                            value: "₹${_analytics?.todayRevenue.toStringAsFixed(0)}",
                            icon: Icons.currency_rupee,
                            color: AppTheme.secondaryMarigold,
                          ),
                          _buildMetricCard(
                            context,
                            title: "Active Plans",
                            value: "${_analytics?.activeSubscribersCount}",
                            icon: Icons.repeat,
                            color: Colors.teal,
                          ),
                          _buildMetricCard(
                            context,
                            title: "Total Customers",
                            value: "${_analytics?.totalCustomers}",
                            icon: Icons.people,
                            color: Colors.blueGrey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Administrative Action Routes
                      Text(
                        "Quick Operations",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      _buildQuickActionTile(
                        context,
                        title: "Update Today's Menu",
                        subtitle: "Edit the dishes, pricing, and tiffin options",
                        icon: Icons.restaurant,
                        destination: const AdminMenuManagement(),
                      ),
                      _buildQuickActionTile(
                        context,
                        title: "Manage Coupon Codes",
                        subtitle: "Create, enable, or disable discount offers",
                        icon: Icons.local_offer,
                        destination: const AdminCouponManagement(),
                      ),
                      _buildQuickActionTile(
                        context,
                        title: "Manage Incoming Orders",
                        subtitle: "Track, skip, or modify active subscriptions",
                        icon: Icons.list_alt,
                        destination: const AdminOrderList(),
                      ),
                      const SizedBox(height: 32),

                      // Coupon performance overview
                      Text(
                        "Popular Coupons Usage",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderLight),
                        ),
                        child: Column(
                          children: _analytics?.couponStats.map((stat) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.confirmation_number_outlined, size: 20, color: AppTheme.secondaryMarigold),
                                          const SizedBox(width: 12),
                                          Text(
                                            stat['code'] ?? '',
                                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        "${stat['usageCount']} uses",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList() ??
                              [const Text("No coupon analytics loaded")],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'PlusJakartaSans'),
              ),
              Icon(icon, color: color, size: 22),
            ],
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppTheme.textDark,
                  fontFamily: 'Outfit',
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_forward_ios, size: 0), // hack to keep alignment
        ),
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Outfit')),
          ],
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destination),
          ).then((_) => _loadAnalytics()); // Reload analytics when returning
        },
      ),
    );
  }
}
