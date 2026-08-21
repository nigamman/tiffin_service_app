import 'package:flutter/material.dart';
import '../data/admin_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class AdminCouponManagement extends StatefulWidget {
  const AdminCouponManagement({Key? key}) : super(key: key);

  @override
  State<AdminCouponManagement> createState() => _AdminCouponManagementState();
}

class _AdminCouponManagementState extends State<AdminCouponManagement> {
  final AdminRepository _repository = AdminRepository();
  bool _isLoading = true;
  List<CouponAdminModel> _coupons = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _repository.getCoupons();
      setState(() {
        _coupons = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showCreateCouponSheet() {
    final codeController = TextEditingController();
    final valueController = TextEditingController();
    final minOrderController = TextEditingController(text: "0");
    String discountType = 'fixed';

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Create New Coupon",
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Code
                    TextFormField(
                      controller: codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(labelText: "Coupon Code (e.g. KANPUR100)"),
                      validator: (v) => (v == null || v.isEmpty) ? "Code is required" : null,
                    ),
                    const SizedBox(height: 12),

                    // Discount Type Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Discount Type:", style: TextStyle(fontWeight: FontWeight.bold)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text("Fixed Amount (₹)"),
                              selected: discountType == 'fixed',
                              onSelected: (selected) {
                                if (selected) setModalState(() => discountType = 'fixed');
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text("Percentage (%)"),
                              selected: discountType == 'percent',
                              onSelected: (selected) {
                                if (selected) setModalState(() => discountType = 'percent');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Discount Value
                    TextFormField(
                      controller: valueController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: discountType == 'fixed' ? "Discount Value (₹)" : "Discount Value (%)",
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Value is required";
                        if (double.tryParse(v) == null) return "Enter a valid number";
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Min Order Value
                    TextFormField(
                      controller: minOrderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Minimum Order Value Required (₹)"),
                      validator: (v) {
                        if (v == null || v.isEmpty) return "Min order is required";
                        if (double.tryParse(v) == null) return "Enter a valid number";
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    CustomButton(
                      text: "Register Coupon",
                      onPressed: () async {
                        if (formKey.currentState?.validate() ?? false) {
                          try {
                            await _repository.createCoupon(
                              code: codeController.text.trim(),
                              discountType: discountType,
                              discountValue: double.parse(valueController.text.trim()),
                              minOrderValue: double.parse(minOrderController.text.trim()),
                            );
                            Navigator.pop(context);
                            _loadCoupons();
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(content: Text("New coupon created successfully")),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text("Failed to create coupon: $e"),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Manage Coupons"),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: AppTheme.primaryGreen),
            onPressed: _showCreateCouponSheet,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Error: $_error"),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadCoupons, child: const Text("Retry")),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCoupons,
                  color: AppTheme.primaryGreen,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: _coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = _coupons[index];
                      final isPercent = coupon.discountType == 'percent';
                      final valueText = isPercent ? "${coupon.discountValue.toStringAsFixed(0)}%" : "₹${coupon.discountValue.toStringAsFixed(0)}";

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppTheme.secondaryMarigold.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          coupon.code,
                                          style: const TextStyle(
                                            color: AppTheme.secondaryMarigold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        "($valueText OFF)",
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Min order: ₹${coupon.minOrderValue.toStringAsFixed(0)} • Used: ${coupon.usageCount} times",
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                              Switch(
                                value: coupon.active,
                                activeColor: AppTheme.primaryGreen,
                                onChanged: (val) async {
                                  try {
                                    await _repository.toggleCoupon(coupon.id);
                                    _loadCoupons();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Failed to toggle: $e"),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
