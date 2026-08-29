import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'booking_cubit.dart';
import '../../home/data/menu_repository.dart';
import '../../../core/theme/app_theme.dart';

class FrequencySelectionStep extends StatelessWidget {
  final MenuModel menu;

  const FrequencySelectionStep({Key? key, required this.menu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BookingCubit, BookingState>(
      builder: (context, state) {
        final double pricePerMeal = menu.price; // E.g. ₹120 or ₹80
        
        // Find current frequency tab: 'one-time', 'weekly', or 'monthly'
        String currentTab = 'weekly';
        if (state.frequency.startsWith('one-time')) {
          currentTab = 'one-time';
        } else if (state.frequency.startsWith('monthly')) {
          currentTab = 'monthly';
        }

        // Available plans based on active tab
        final List<Map<String, dynamic>> plans = [];
        if (currentTab == 'one-time') {
          plans.add({
            'key': 'one-time',
            'title': '1 Day Plan',
            'days': 1,
            'desc': 'Single delivery slot selection',
            'subtitle': 'Today / Tomorrow',
            'saveAmountPerDay': 0.0,
          });
        } else if (currentTab == 'weekly') {
          plans.addAll([
            {
              'key': 'weekly_5',
              'title': '5 Days Plan',
              'days': 5,
              'desc': 'Lunch & Dinner',
              'subtitle': 'Mon - Fri',
              'saveAmountPerDay': 40.0,
              'popular': true,
            },
            {
              'key': 'weekly_6',
              'title': '6 Days Plan',
              'days': 6,
              'desc': 'Lunch & Dinner',
              'subtitle': 'Mon - Sat',
              'saveAmountPerDay': 40.0,
            },
            {
              'key': 'weekly_7',
              'title': '7 Days Plan',
              'days': 7,
              'desc': 'Lunch & Dinner',
              'subtitle': 'Mon - Sun',
              'saveAmountPerDay': 40.0,
            },
          ]);
        } else {
          plans.addAll([
            {
              'key': 'monthly_20',
              'title': '20 Days Plan',
              'days': 20,
              'desc': 'Lunch & Dinner',
              'subtitle': 'Mon - Fri',
              'saveAmountPerDay': 40.0,
              'popular': true,
            },
            {
              'key': 'monthly_24',
              'title': '24 Days Plan',
              'days': 24,
              'desc': 'Lunch & Dinner',
              'subtitle': 'Mon - Sat',
              'saveAmountPerDay': 40.0,
            },
            {
              'key': 'monthly_30',
              'title': '30 Days Plan',
              'days': 30,
              'desc': 'Lunch & Dinner',
              'subtitle': 'Mon - Sun',
              'saveAmountPerDay': 40.0,
            },
          ]);
        }

        // Slot Multiplier calculations
        final bool isLunchSelected = state.deliverySlot == 'lunch' || state.deliverySlot == 'both';
        final bool isDinnerSelected = state.deliverySlot == 'dinner' || state.deliverySlot == 'both';
        final double slotMultiplier = state.deliverySlot == 'both' ? 2.0 : 1.0;
        final int weeksMultiplier = currentTab == 'weekly' ? 2 : 1;

        // Calculate checkout total and savings
        double currentPlanDays = 5.0;
        if (currentTab == 'one-time') {
          currentPlanDays = 1.0;
        } else {
          final matched = plans.firstWhere(
            (p) => p['key'] == state.frequency,
            orElse: () => plans.first,
          );
          currentPlanDays = (matched['days'] as int).toDouble();
        }

        // Math matching finalized mockup
        // E.g. Subtotal for 5 Days = ₹120 * 5 * 2 (slots) * 2 (weeks) = ₹2,400.
        // Original price = retail (subtotal + savings)
        final double saveAmount = currentPlanDays * slotMultiplier * weeksMultiplier * 40.0; // saving ₹40 per thali
        final double subtotal = pricePerMeal * currentPlanDays * slotMultiplier * weeksMultiplier * state.quantity;
        final double finalPrice = subtotal;
        final double originalPrice = subtotal + saveAmount;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Choose Your Plan",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Flexible plans, made for you.",
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Selector tabs segment row (One-time, Weekly, Monthly)
                    _buildTabSelector(context, currentTab),
                    const SizedBox(height: 24),

                    // 2. Active plan cards list
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: plans.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        final isSelected = state.frequency == plan['key'] || 
                            (currentTab == 'one-time' && state.frequency == 'one-time');

                        final double planDays = (plan['days'] as int).toDouble();
                        final double planSubtotal = pricePerMeal * planDays * slotMultiplier * weeksMultiplier * state.quantity;
                        final double planSave = planDays * slotMultiplier * weeksMultiplier * 40.0;
                        final double planOriginal = planSubtotal + planSave;

                        return _buildPlanCard(
                          context: context,
                          plan: plan,
                          isSelected: isSelected,
                          price: planSubtotal,
                          originalPrice: planOriginal,
                          save: planSave,
                          slotText: state.deliverySlot == 'both' ? 'Lunch & Dinner' : (state.deliverySlot == 'lunch' ? 'Lunch Only' : 'Dinner Only'),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // 3. Customize Slots Section
                    Text(
                      "Customize Slots",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEDE8E0), width: 1),
                      ),
                      child: Column(
                        children: [
                          _buildSlotCheckbox(
                            title: "Lunch (11:30 AM - 1:30 PM)",
                            isSelected: isLunchSelected,
                            onChanged: (val) {
                              _updateSlots(context, val ?? false, isDinnerSelected);
                            },
                          ),
                          const Divider(color: Color(0xFFEDE8E0), height: 1),
                          _buildSlotCheckbox(
                            title: "Dinner (7:00 PM - 9:00 PM)",
                            isSelected: isDinnerSelected,
                            onChanged: (val) {
                              _updateSlots(context, isLunchSelected, val ?? false);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Sticky Bottom Summary & Checkout Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
                border: const Border(
                  top: BorderSide(color: Color(0xFFEDE8E0), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Total Price display
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Total",
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              "₹${finalPrice.toStringAsFixed(0)}",
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ],
                        ),
                        if (saveAmount > 0)
                          Text(
                            "You save ₹${saveAmount.toStringAsFixed(0)}",
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: const Color(0xFFC3A575),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Continue to Checkout CTA
                  Expanded(
                    flex: 6,
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<BookingCubit>().nextStep();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F3A20),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Continue to Checkout",
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // --- Horizontal Tab Selector ---
  Widget _buildTabSelector(BuildContext context, String currentTab) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8E0).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(child: _buildTabPill(context, "One-time", 'one-time', currentTab)),
          Expanded(child: _buildTabPill(context, "Weekly", 'weekly', currentTab)),
          Expanded(child: _buildTabPill(context, "Monthly", 'monthly', currentTab)),
        ],
      ),
    );
  }

  Widget _buildTabPill(BuildContext context, String title, String value, String selectedValue) {
    final isSelected = value == selectedValue;
    return GestureDetector(
      onTap: () {
        // Set default plan key for each tab
        if (value == 'one-time') {
          context.read<BookingCubit>().setFrequency('one-time');
        } else if (value == 'weekly') {
          context.read<BookingCubit>().setFrequency('weekly_5');
        } else {
          context.read<BookingCubit>().setFrequency('monthly_20');
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F3A20) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : AppTheme.textMuted,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // --- Plan Card Item ---
  Widget _buildPlanCard({
    required BuildContext context,
    required Map<String, dynamic> plan,
    required bool isSelected,
    required double price,
    required double originalPrice,
    required double save,
    required String slotText,
  }) {
    final isPopular = plan['popular'] ?? false;

    return GestureDetector(
      onTap: () {
        context.read<BookingCubit>().setFrequency(plan['key'] as String);
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? const Color(0xFFC3A575) : const Color(0xFFEDE8E0),
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFC3A575).withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Plan Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F3A20) : const Color(0xFFFBF9F6),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.calendar_today_outlined,
                    color: isSelected ? const Color(0xFFC3A575) : AppTheme.textMuted,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan['title'] as String,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        "$slotText • ${plan['subtitle']}",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Pricing Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${price.toStringAsFixed(0)}",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    if (save > 0) ...[
                      Text(
                        "₹${originalPrice.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textMuted,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        "Save ₹${save.toStringAsFixed(0)}",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFFC3A575),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(width: 8),

                // Check circle
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_off,
                  color: isSelected ? const Color(0xFF0F3A20) : const Color(0xFFEDE8E0),
                  size: 20,
                ),
              ],
            ),
          ),

          // "MOST POPULAR" Ribbon
          if (isPopular && isSelected)
            Positioned(
              top: -10,
              left: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFC3A575),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "MOST POPULAR",
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF0F3A20),
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // --- Checkbox Row ---
  Widget _buildSlotCheckbox({
    required String title,
    required bool isSelected,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.textDark,
        ),
      ),
      value: isSelected,
      onChanged: onChanged,
      activeColor: const Color(0xFF0F3A20),
      checkboxShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.trailing,
    );
  }

  void _updateSlots(BuildContext context, bool lunchChecked, bool dinnerChecked) {
    final state = context.read<BookingCubit>().state;
    String newSlot = 'both';
    if (lunchChecked && !dinnerChecked) {
      newSlot = 'lunch';
    } else if (!lunchChecked && dinnerChecked) {
      newSlot = 'dinner';
    } else if (!lunchChecked && !dinnerChecked) {
      // Must have at least one selected, default back to lunch
      newSlot = 'lunch';
    }
    context.read<BookingCubit>().updateMealDetails(state.quantity, state.startDate, newSlot);
  }
}
