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

  const BookingFlowScreen({Key? key, required this.menu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = BookingCubit();
        
        // Pre-fill user phone and address if logged in, to make checkout extremely smooth!
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
          // Confirm discard booking flow
          return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Exit Checkout?", style: TextStyle(fontFamily: 'Outfit')),
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

            final stepTitles = ["Frequency", "Address", "Summary"];

            return Scaffold(
              backgroundColor: AppTheme.backgroundLight,
              appBar: AppBar(
                title: Text("Checkout - ${stepTitles[state.step]}"),
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
                  // Step Indicator Header
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    child: Row(
                      children: List.generate(steps.length, (index) {
                        final isCompleted = index < state.step;
                        final isActive = index == state.step;
                        return Expanded(
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: isActive || isCompleted
                                      ? AppTheme.primaryGreen
                                      : AppTheme.borderLight,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: isCompleted
                                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                                      : Text(
                                          "${index + 1}",
                                          style: TextStyle(
                                            color: isActive || isCompleted
                                                ? Colors.white
                                                : AppTheme.textMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                stepTitles[index],
                                style: TextStyle(
                                  color: isActive
                                      ? AppTheme.primaryGreen
                                      : isCompleted
                                          ? AppTheme.textDark
                                          : AppTheme.textMuted,
                                  fontWeight: isActive || isCompleted
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                  fontFamily: 'Outfit',
                                ),
                              ),
                              if (index < steps.length - 1)
                                const Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                                    child: Divider(color: AppTheme.borderLight, thickness: 1),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
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
