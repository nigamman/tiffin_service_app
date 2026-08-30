import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/data/menu_repository.dart';
import '../../auth/presentation/auth_cubit.dart';
import 'booking_cubit.dart';
import 'frequency_selection_step.dart';
import 'delivery_details_step.dart';
import 'order_summary_step.dart';
import '../../../core/theme/app_theme.dart';

class BookingFlowScreen extends StatelessWidget {
  final MenuModel menu;
  final String initialSlot;
  final DateTime? initialStartDate;
  final int initialQuantity;

  const BookingFlowScreen({
    Key? key,
    required this.menu,
    this.initialSlot = 'lunch',
    this.initialStartDate,
    this.initialQuantity = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = BookingCubit(
          initialSlot: initialSlot,
          initialStartDate: initialStartDate,
          initialQuantity: initialQuantity,
        );
        
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          final user = authState.user;
          cubit.setAddressDetails(
            houseNo: user.houseNo,
            area: user.area,
            landmark: user.landmark,
            phone: user.phone,
          );
        }
        
        return cubit;
      },
      child: WillPopScope(
        onWillPop: () async {
          return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Cancel Checkout?"),
                  content: const Text("Are you sure you want to stop booking your tiffin? All details will be lost."),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Keep Booking"),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("Exit"),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        child: BlocBuilder<BookingCubit, BookingState>(
          builder: (context, state) {
            final steps = [
              FrequencySelectionStep(menu: menu),
              const DeliveryDetailsStep(),
              OrderSummaryStep(menu: menu),
            ];

            final stepTitles = ["Choose Frequency", "Delivery Address", "Verify Summary"];

            return Scaffold(
              backgroundColor: AppTheme.backgroundLight,
              appBar: AppBar(
                title: Text(
                  stepTitles[state.step],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (state.step > 0) {
                      context.read<BookingCubit>().prevStep();
                    } else {
                      Navigator.maybePop(context);
                    }
                  },
                ),
              ),
              body: Column(
                children: [
                  // Premium Stories-style Step Indicator Bar
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Thin Segment Bars
                        Row(
                          children: List.generate(steps.length, (index) {
                            final isCompleted = index < state.step;
                            final isActive = index == state.step;
                            
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: index < steps.length - 1 ? 6.0 : 0.0,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive || isCompleted
                                      ? AppTheme.primaryGreen
                                      : AppTheme.borderLight,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 12),
                        
                        // Editorial text indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "STEP ${state.step + 1} OF 3",
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryMarigold,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              state.step < steps.length - 1 
                                  ? "Next: ${stepTitles[state.step + 1]}"
                                  : "Final Step",
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderLight),
                    // Current Step Display
                    Expanded(
                      child: steps[state.step],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
  }
}
