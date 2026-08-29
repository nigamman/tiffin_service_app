import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/presentation/menu_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class AdminMenuManagement extends StatefulWidget {
  const AdminMenuManagement({Key? key}) : super(key: key);

  @override
  State<AdminMenuManagement> createState() => _AdminMenuManagementState();
}

class _AdminMenuManagementState extends State<AdminMenuManagement> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _priceController;
  final List<TextEditingController> _itemControllers = [];
  bool _isLoading = false;
  String _selectedSlot = 'lunch';

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
    _loadMenuFields();
  }

  void _loadMenuFields() {
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    _itemControllers.clear();
    final menuState = context.read<MenuCubit>().state;
    if (menuState is MenuLoaded) {
      final menu = _selectedSlot == 'lunch' ? menuState.lunchMenu : menuState.dinnerMenu;
      _priceController.text = menu.price.toStringAsFixed(0);
      for (final item in menu.items) {
        _itemControllers.add(TextEditingController(text: item));
      }
    } else {
      final defaults = _selectedSlot == 'lunch' 
          ? ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle']
          : ['Paneer Butter Masala', 'Veg Jhalfrezi', '4 Roti', 'Steamed Rice', 'Salad', 'Rayta'];
      _priceController.text = _selectedSlot == 'lunch' ? "80" : "90";
      for (final item in defaults) {
        _itemControllers.add(TextEditingController(text: item));
      }
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    for (final controller in _itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addItemField() {
    setState(() {
      _itemControllers.add(TextEditingController());
    });
  }

  void _removeItemField(int index) {
    if (_itemControllers.length > 1) {
      setState(() {
        _itemControllers[index].dispose();
        _itemControllers.removeAt(index);
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final double price = double.tryParse(_priceController.text) ?? 80.0;
      final List<String> items = _itemControllers
          .map((c) => c.text.trim())
          .where((text) => text.isNotEmpty)
          .toList();

      try {
        await context.read<MenuCubit>().updateMenu(items, price, slot: _selectedSlot);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("${_selectedSlot[0].toUpperCase()}${_selectedSlot.substring(1)} menu updated successfully!")),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update menu: $e"),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("Manage Today's Menu"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tiffin Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),

              // Slot Toggle (Lunch / Dinner)
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedSlot != 'lunch') {
                            setState(() {
                              _selectedSlot = 'lunch';
                              _loadMenuFields();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSlot == 'lunch' ? AppTheme.primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Lunch Menu",
                            style: TextStyle(
                              color: _selectedSlot == 'lunch' ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (_selectedSlot != 'dinner') {
                            setState(() {
                              _selectedSlot = 'dinner';
                              _loadMenuFields();
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedSlot == 'dinner' ? AppTheme.primaryGreen : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "Dinner Menu",
                            style: TextStyle(
                              color: _selectedSlot == 'dinner' ? Colors.white : AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Meal Price Input
              Text(
                "Meal Price (₹)",
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "e.g. 80"),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Price is required";
                  if (double.tryParse(v) == null) return "Enter a valid number";
                  return null;
                },
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Include Menu Items",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text("Add Item"),
                    onPressed: _addItemField,
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // List of dynamic text fields for items
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemControllers.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _itemControllers[index],
                            decoration: InputDecoration(
                              hintText: "e.g. Seasonal Sabzi, Roti",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            ),
                            validator: (v) => (v == null || v.isEmpty) ? "Item cannot be blank" : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                          onPressed: () => _removeItemField(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              CustomButton(
                text: "Save & Update Menu",
                isLoading: _isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
