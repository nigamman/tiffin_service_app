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
              const Text(
                "Choose Plan Frequency",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 16),

              // Frequency Cards List
              _buildPremiumFrequencyCard(
                context,
                title: "One Time",
                description: "Just one single home-cooked meal.",
                value: "one-time",
                priceTag: "₹${mealPrice.toStringAsFixed(0)}",
                selectedValue: state.frequency,
              ),
              const SizedBox(height: 12),
              _buildPremiumFrequencyCard(
                context,
                title: "Daily Plan",
                description: "Fresh box delivered daily (7-meal sub).",
                value: "daily",
                priceTag: "₹${(mealPrice * 7).toStringAsFixed(0)}",
                selectedValue: state.frequency,
                badgeText: "POPULAR",
              ),
              const SizedBox(height: 12),
              _buildPremiumFrequencyCard(
                context,
                title: "Weekly Plan",
                description: "Enjoy 7 tiffins over a week.",
                value: "weekly",
                priceTag: "₹${(mealPrice * 7).toStringAsFixed(0)}",
                selectedValue: state.frequency,
              ),
              const SizedBox(height: 12),
              _buildPremiumFrequencyCard(
                context,
                title: "Monthly Plan",
                description: "30-day corporate/home tiffin plan.",
                value: "monthly",
                priceTag: "₹${(mealPrice * 30).toStringAsFixed(0)}",
                selectedValue: state.frequency,
                badgeText: "BEST VALUE",
              ),
              const SizedBox(height: 32),

              const Text(
                "Quantity & Timings",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 16),

              // Quantity Selector Card (Premium details card)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight, width: 0.8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Tiffin Quantity",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            Text(
                              "Number of tiffins per delivery slot",
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
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
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark, fontFamily: 'Outfit'),
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
                    const Divider(height: 24, color: AppTheme.borderLight),
                    
                    // Slot choice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Delivery Slot",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            Text(
                              "Choose lunch or dinner delivery",
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            _buildSlotChip(context, "Lunch", "lunch", state.deliverySlot),
                            const SizedBox(width: 8),
                            _buildSlotChip(context, "Dinner", "dinner", state.deliverySlot),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24, color: AppTheme.borderLight),

                    // Date Picker Choice
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Plan Start Date",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                            ),
                            Text(
                              "Choose when deliveries start",
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryGreen,
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.06),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          icon: const Icon(Icons.calendar_today, size: 14),
                          label: Text(
                            DateFormat('dd MMM, yyyy').format(state.startDate),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Outfit'),
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
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Subtotal pricing card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "ESTIMATED TOTAL",
                          style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "₹${mealPrice.toStringAsFixed(0)} × $mealsCount meals × ${state.quantity} box",
                          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9), fontFamily: 'PlusJakartaSans'),
                        ),
                      ],
                    ),
                    Text(
                      "₹${totalRaw.toStringAsFixed(0)}",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Outfit',
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
        color: AppTheme.primaryGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: AppTheme.primaryGreen, size: 16),
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildSlotChip(BuildContext context, String label, String value, String selectedValue) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () {
        final state = context.read<BookingCubit>().state;
        context.read<BookingCubit>().updateMealDetails(state.quantity, state.startDate, value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen : Colors.white,
          border: Border.all(color: AppTheme.primaryGreen, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.primaryGreen,
            fontWeight: FontWeight.bold,
            fontSize: 12,
            fontFamily: 'Outfit',
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumFrequencyCard(
    BuildContext context, {
    required String title,
    required String description,
    required String value,
    required String priceTag,
    required String selectedValue,
    String? badgeText,
  }) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () => context.read<BookingCubit>().setFrequency(value),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.borderLight,
            width: isSelected ? 1.8 : 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              children: [
                // Radio/Check circle indicators
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryGreen : Colors.white,
                    border: Border.all(
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.borderLight,
                      width: 1.5,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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
            
            // Premium micro-badge overlay
            if (badgeText != null)
              Positioned(
                top: -24,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryMarigold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      fontFamily: 'Outfit',
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
