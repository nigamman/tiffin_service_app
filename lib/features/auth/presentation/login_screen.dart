import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_cubit.dart';
import 'otp_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().sendOtp(_phoneController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(phone: state.phone),
            ),
          );
        } else if (state is AuthAuthenticated) {
          Navigator.maybePop(context);
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 64,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          // Brand Icon/Visual
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen.withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                size: 64,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Text(
                              "Atithi Bhoj Tiffin Service",
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              "Fresh, homemade meals to your door",
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const Spacer(flex: 2),
                          Text(
                            "Get Started",
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter your phone number to receive a 6-digit verification code.",
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  letterSpacing: 2,
                                  fontWeight: FontWeight.bold,
                                ),
                            decoration: InputDecoration(
                              prefixIcon: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    right: BorderSide(color: AppTheme.borderLight),
                                  ),
                                ),
                                child: Text(
                                  "+91",
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                              hintText: "Enter Phone Number",
                              counterText: "",
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please enter phone number";
                              }
                              if (value.length < 10) {
                                return "Please enter a valid 10-digit number";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          // Verify CTA
                           BlocBuilder<AuthCubit, AuthState>(
                             builder: (context, state) {
                               return CustomButton(
                                 text: "Get OTP",
                                 isLoading: state is AuthLoading && state is! AuthOtpSent,
                                 onPressed: _submit,
                               );
                             },
                           ),
                           const SizedBox(height: 24),
                           // OR Divider
                           const Row(
                             children: [
                               Expanded(child: Divider(color: AppTheme.borderLight, thickness: 1)),
                               Padding(
                                 padding: EdgeInsets.symmetric(horizontal: 16.0),
                                 child: Text(
                                   "OR",
                                   style: TextStyle(
                                     color: AppTheme.textMuted,
                                     fontSize: 12,
                                     fontWeight: FontWeight.bold,
                                   ),
                                 ),
                               ),
                               Expanded(child: Divider(color: AppTheme.borderLight, thickness: 1)),
                             ],
                           ),
                           const SizedBox(height: 24),
                           // Google Sign-In Button
                           BlocBuilder<AuthCubit, AuthState>(
                             builder: (context, state) {
                               return _buildGoogleSignInButton(context, state);
                             },
                           ),
                           const Spacer(flex: 3),
                          // Trust Footer
                          const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.security, size: 14, color: AppTheme.textMuted),
                                SizedBox(width: 6),
                                Text(
                                  "100% safe & secure checkout",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
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

  Widget _buildGoogleSignInButton(BuildContext context, AuthState state) {
    final isLoading = state is AuthLoading;
    
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : () => context.read<AuthCubit>().signInWithGoogle(),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png',
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                "G",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Continue with Google",
                        style: TextStyle(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
