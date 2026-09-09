import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/admin_repository.dart';
import 'admin_menu_management.dart';
import 'admin_coupon_management.dart';
import 'admin_order_list.dart';
import 'admin_subscription_list_screen.dart';
import 'admin_notification_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/firebase_service.dart';

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
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AdminSubscriptionListScreen()),
                              ).then((_) => _loadAnalytics());
                            },
                            child: _buildMetricCard(
                              context,
                              title: "Active Plans",
                              value: "${_analytics?.activeSubscribersCount}",
                              icon: Icons.repeat,
                              color: Colors.teal,
                            ),
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
                        subtitle: "Track or modify active subscriptions",
                        icon: Icons.list_alt,
                        destination: const AdminOrderList(),
                      ),
                      _buildQuickActionTile(
                        context,
                        title: "Active Subscriptions",
                        subtitle: "Track tiffin consumption (got/left) per subscriber",
                        icon: Icons.people_outline,
                        destination: const AdminSubscriptionListScreen(),
                      ),
                      _buildQuickActionTile(
                        context,
                        title: "Send Custom Notifications",
                        subtitle: "Broadcast alerts or message specific customers",
                        icon: Icons.campaign_outlined,
                        destination: const AdminNotificationScreen(),
                      ),
                      Container(
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
                            child: const Icon(Icons.arrow_forward_ios, size: 0),
                          ),
                          title: const Row(
                            children: [
                              Icon(Icons.system_update_rounded, size: 20, color: AppTheme.primaryGreen),
                              SizedBox(width: 10),
                              Text("App Version & Release Control", style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          subtitle: const Text("Set required app version & push update alerts", style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textMuted),
                          onTap: () => _showVersionControlDialog(context),
                        ),
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
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
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
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
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

  void _showVersionControlDialog(BuildContext context) async {
    final versionCodeController = TextEditingController(text: "3");
    final titleController = TextEditingController(text: "New Update Available 🚀");
    final messageController = TextEditingController(
      text: "A new version of Atithi Bhoj is available on Google Play Store with performance improvements and bug fixes.",
    );
    bool forceUpdate = false;
    bool isSaving = false;

    // Load current config from Firestore if available
    try {
      final config = await FirebaseService.instance.docGet('app_config', 'version_info');
      if (config != null) {
        final currentCode = (config['latestVersionCode'] as num?)?.toInt() ?? 3;
        versionCodeController.text = currentCode.toString();
        if (config['updateTitle'] != null) titleController.text = config['updateTitle'].toString();
        if (config['updateMessage'] != null) messageController.text = config['updateMessage'].toString();
        forceUpdate = config['forceUpdate'] == true;
      }
    } catch (_) {}

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.system_update_rounded, color: AppTheme.primaryGreen),
                  const SizedBox(width: 10),
                  Text(
                    "App Version Control",
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Set the version code for your latest Play Store release. App users on older versions will be prompted to update.",
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: versionCodeController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: "Latest Version Code (e.g. 3)",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: "Update Alert Title",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: "Update Message",
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        "Force Mandatory Update",
                        style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "If enabled, users must update to continue using the app.",
                        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
                      ),
                      value: forceUpdate,
                      activeColor: AppTheme.primaryGreen,
                      onChanged: (val) {
                        setDialogState(() => forceUpdate = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel", style: GoogleFonts.poppins(color: AppTheme.textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setDialogState(() => isSaving = true);
                          final int? code = int.tryParse(versionCodeController.text.trim());
                          if (code == null) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please enter a valid version code number")),
                            );
                            return;
                          }

                          await FirebaseService.instance.docSet('app_config', 'version_info', {
                            'latestVersionCode': code,
                            'minRequiredVersionCode': forceUpdate ? code : 1,
                            'updateTitle': titleController.text.trim(),
                            'updateMessage': messageController.text.trim(),
                            'forceUpdate': forceUpdate,
                            'updatedAt': DateTime.now().toIso8601String(),
                          });

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("App update release alert config published to Firestore! 🚀"),
                                backgroundColor: AppTheme.primaryGreen,
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text("Publish Release Alert", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
