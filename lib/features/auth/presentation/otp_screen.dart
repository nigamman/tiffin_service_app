import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String verificationId;
  final String name;

  const OtpScreen({
    Key? key,
    required this.phone,
    required this.verificationId,
    required this.name,
  }) : super(key: key);

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _verify() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().verifyOtp(
        phone: widget.phone,
        otp: _otpController.text.trim(),
        verificationId: widget.verificationId,
        name: widget.name,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          // Success! Pop back to root so home is shown
          Navigator.popUntil(context, (route) => route.isFirst);
        } else if (state is AuthError) {
          if (state.isSmsUnavailable) {
            _showQuotaExceededDialog(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppTheme.errorColor,
              ),
            );
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppTheme.backgroundLight,
          elevation: 0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            "Verify Phone",
                            style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          RichText(
                            text: TextSpan(
                              style: Theme.of(context).textTheme.bodyMedium,
                              children: [
                                const TextSpan(text: "We sent a 6-digit OTP code to "),
                                TextSpan(
                                  text: "+91 ${widget.phone}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // OTP Input field
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: const InputDecoration(
                              hintText: "000000",
                              counterText: "",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter the OTP code";
                              }
                              if (value.length < 6) {
                                return "OTP must be 6 digits";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(height: 32),
                          BlocBuilder<AuthCubit, AuthState>(
                            builder: (context, state) {
                              return CustomButton(
                                text: "Verify & Proceed",
                                isLoading: state is AuthLoading,
                                onPressed: _verify,
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                context.read<AuthCubit>().sendOtp(widget.phone, widget.name);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("OTP resent successfully"),
                                    duration: Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: const Text("Resend OTP"),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showQuotaExceededDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppTheme.secondaryMarigold, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  "OTP Service Unavailable",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: const Text(
            "Due to an internal issue, the SMS OTP service is temporarily unavailable. "
            "Please log in using your Google account to continue instantly.",
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // Pop dialog and pop OTP screen back to Welcome / Root to clear state cleanly
                    Navigator.pop(dialogContext);
                    Navigator.pop(context);
                    context.read<AuthCubit>().signInWithGoogle();
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text("Log In with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
