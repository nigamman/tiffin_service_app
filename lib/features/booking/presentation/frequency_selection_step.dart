import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../home/data/menu_repository.dart';
import 'booking_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class FrequencySelectionStep extends StatelessWidget {
  final MenuModel menu;

  const FrequencySelectionStep({Key? key, required this.menu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final double mealPrice = menu.price;
        int mealsCount = 1;
        if (state.frequency == 'weekly' || state.frequency == 'daily') mealsCount = 7;
        if (state.frequency == 'monthly') mealsCount = 30;
        final double totalRaw = mealPrice * mealsCount * state.quantity;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "How often do you want your tiffin?",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Frequency Cards List
              _buildFrequencyCard(
                context,
                title: "One Time",
                description: "Just one delicious test meal.",
                value: "one-time",
                priceTag: "₹${mealPrice.toStringAsFixed(0)}",
                selectedValue: state.frequency,
              ),
              const SizedBox(height: 12),
              _buildFrequencyCard(
                context,
                title: "Daily Plan",
                description: "Delivered daily (7-meals recurring).",
                value: "daily",
                priceTag: "₹${(mealPrice * 7).toStringAsFixed(0)}",
                selectedValue: state.frequency,
              ),
              const SizedBox(height: 12),
              _buildFrequencyCard(
                context,
                title: "Weekly Plan",
                description: "Enjoy 7 meals delivered over a week.",
                value: "weekly",
                priceTag: "₹${(mealPrice * 7).toStringAsFixed(0)}",
                selectedValue: state.frequency,
              ),
              const SizedBox(height: 12),
              _buildFrequencyCard(
                context,
                title: "Monthly Plan",
                description: "30-day premium local plan.",
                value: "monthly",
                priceTag: "₹${(mealPrice * 30).toStringAsFixed(0)}",
                selectedValue: state.frequency,
              ),
              const SizedBox(height: 28),

              Text(
                "Meal Details",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Quantity Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Tiffin Quantity",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  Row(
                    children: [
                      _buildQtyButton(
                        icon: Icons.remove,
                        onPressed: state.quantity > 1
                            ? () => context.read<BookingCubit>().updateMealDetails(
                                  state.quantity - 1,
                                  state.startDate,
                                  state.deliverySlot,
                                )
                            : null,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          "${state.quantity}",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                        ),
                      ),
                      _buildQtyButton(
                        icon: Icons.add,
                        onPressed: () => context.read<BookingCubit>().updateMealDetails(
                              state.quantity + 1,
                              state.startDate,
                              state.deliverySlot,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Delivery Slot Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Delivery Slot",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  Row(
                    children: [
                      _buildSlotChip(
                        context,
                        label: "Lunch",
                        value: "lunch",
                        selectedValue: state.deliverySlot,
                      ),
                      const SizedBox(width: 8),
                      _buildSlotChip(
                        context,
                        label: "Dinner",
                        value: "dinner",
                        selectedValue: state.deliverySlot,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Start Date Picker
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Start Date",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                    icon: const Icon(Icons.calendar_month, size: 20),
                    label: Text(
                      DateFormat('dd MMM, yyyy').format(state.startDate),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final chosen = await showDatePicker(
                        context: context,
                        initialDate: state.startDate,
                        firstDate: DateTime.now().add(const Duration(days: 1)),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppTheme.primaryGreen,
                                onPrimary: Colors.white,
                                onSurface: AppTheme.textDark,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (chosen != null) {
                        context.read<BookingCubit>().updateMealDetails(
                              state.quantity,
                              chosen,
                              state.deliverySlot,
                            );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Subtotal pricing calculation display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.borderLight.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Subtotal",
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontFamily: 'Outfit'),
                        ),
                        Text(
                          "₹${mealPrice.toStringAsFixed(0)} × $mealsCount meals × ${state.quantity} tiffin",
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                    Text(
                      "₹${totalRaw.toStringAsFixed(0)}",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              CustomButton(
                text: "Continue to Address",
                onPressed: () => context.read<BookingCubit>().nextStep(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQtyButton({required IconData icon, VoidCallback? onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.primaryGreen, size: 18),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSlotChip(
    BuildContext context, {
    required String label,
    required String value,
    required String selectedValue,
  }) {
    final isSelected = value == selectedValue;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryGreen,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          final state = context.read<BookingCubit>().state;
          context.read<BookingCubit>().updateMealDetails(
                state.quantity,
                state.startDate,
                value,
              );
        }
      },
      selectedColor: AppTheme.primaryGreen,
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppTheme.primaryGreen, width: 1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    );
  }

  Widget _buildFrequencyCard(
    BuildContext context, {
    required String title,
    required String description,
    required String value,
    required String priceTag,
    required String selectedValue,
  }) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => context.read<BookingCubit>().setFrequency(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderLight,
            width: isSelected ? 1.8 : 1,
          ),
        ),
        child: Row(
          children: [
            Radio<String>(
              value: value,
              groupValue: selectedValue,
              activeColor: AppTheme.primaryGreen,
              onChanged: (val) {
                if (val != null) {
                  context.read<BookingCubit>().setFrequency(val);
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.textDark,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMuted,
                      fontFamily: 'PlusJakartaSans',
                    ),
                  ),
                ],
              ),
            ),
            Text(
              priceTag,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected ? AppTheme.primaryGreen : AppTheme.textDark,
                fontFamily: 'Outfit',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
