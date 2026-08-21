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

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(text: "80");
    
    // Retrieve today's menu and pre-populate fields
    final menuState = context.read<MenuCubit>().state;
    if (menuState is MenuLoaded) {
      _priceController.text = menuState.menu.price.toStringAsFixed(0);
      for (final item in menuState.menu.items) {
        _itemControllers.add(TextEditingController(text: item));
      }
    } else {
      // Default placeholder fields
      final defaults = ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'];
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
        await context.read<MenuCubit>().updateMenu(items, price);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Today's menu updated successfully!")),
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
