import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'booking_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class DeliveryDetailsStep extends StatefulWidget {
  const DeliveryDetailsStep({Key? key}) : super(key: key);

  @override
  State<DeliveryDetailsStep> createState() => _DeliveryDetailsStepState();
}

class _DeliveryDetailsStepState extends State<DeliveryDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _houseNoController;
  late TextEditingController _areaController;
  late TextEditingController _landmarkController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    final state = context.read<BookingCubit>().state;
    _houseNoController = TextEditingController(text: state.houseNo);
    _areaController = TextEditingController(text: state.area);
    _landmarkController = TextEditingController(text: state.landmark);
    _phoneController = TextEditingController(text: state.contactPhone);
  }

  @override
  void dispose() {
    _houseNoController.dispose();
    _areaController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<BookingCubit>().setAddressDetails(
            houseNo: _houseNoController.text.trim(),
            area: _areaController.text.trim(),
            landmark: _landmarkController.text.trim(),
            phone: _phoneController.text.trim(),
          );
      context.read<BookingCubit>().nextStep();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Where should we deliver?",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              "Deliveries are restricted to active zones in Kanpur.",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // House/Flat No
            Text(
              "House / Flat No.",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _houseNoController,
              decoration: const InputDecoration(
                hintText: "e.g. 10/482, Flat 302",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "House number is required" : null,
            ),
            const SizedBox(height: 18),

            // Area/Locality
            Text(
              "Area / Locality / Street",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _areaController,
              decoration: const InputDecoration(
                hintText: "e.g. Swaroop Nagar, Civil Lines",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Area details are required" : null,
            ),
            const SizedBox(height: 18),

            // Landmark
            Text(
              "Landmark",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                hintText: "e.g. Near HDFC Bank, Opposite Park",
              ),
              validator: (v) => (v == null || v.isEmpty) ? "Please add a nearby landmark" : null,
            ),
            const SizedBox(height: 18),

            // Delivery phone
            Text(
              "Contact Phone Number",
              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.8)),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              decoration: const InputDecoration(
                hintText: "10-digit delivery phone number",
                counterText: "",
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Delivery phone number is required";
                }
                if (value.length < 10) {
                  return "Please enter a valid 10-digit number";
                }
                return null;
              },
            ),
            const SizedBox(height: 36),

            CustomButton(
              text: "Continue to Summary",
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
