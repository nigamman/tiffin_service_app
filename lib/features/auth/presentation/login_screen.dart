import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthCubit>().sendOtp(
        _phoneController.text.trim(),
        _nameController.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthOtpSent) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpScreen(
                phone: state.phone,
                verificationId: state.verificationId,
                name: state.name,
              ),
            ),
          );
        } else if (state is AuthAuthenticated) {
          Navigator.maybePop(context);
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Warm traditional cream background color
            Container(color: const Color(0xFFF7F4EB)),

            // 2. Corner Mandalas
            Positioned(
              top: 0,
              left: 0,
              width: size.width * 0.45,
              child: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/welcome_page/bg2_topleft.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              width: size.width * 0.45,
              child: Opacity(
                opacity: 0.75,
                child: Image.asset(
                  'assets/welcome_page/bg3_topright.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Kanpur monument subtle watermark at bottom center
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.25,
              child: Opacity(
                opacity: 0.08,
                child: Image.asset(
                  'assets/welcome_page/bg5_line.png',
                  fit: BoxFit.fitHeight,
                ),
              ),
            ),

            // 3. Main Content
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 32,
                      ),
                      child: IntrinsicHeight(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Spacer(flex: 2),

                              // Brand App Icon in Premium Gold Frame
                              Center(
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(
                                      color: const Color(0xFFC3A575),
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0F3A20).withOpacity(0.08),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(60),
                                    child: Image.asset(
                                      'assets/icons/atithibhoj_appicon.png',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Brand Name
                              Center(
                                child: Text(
                                  "Atithi Bhoj",
                                  style: GoogleFonts.poppins(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF0F3A20),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),

                              // Wave underliner flourish
                              Center(
                                child: CustomPaint(
                                  size: const Size(120, 10),
                                  painter: _SimpleWavePainter(),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Brand Tagline
                              Center(
                                child: Text(
                                  "Ghar jaisa swaad, har roz aapke saath.",
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF8C7144),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const Spacer(flex: 3),

                              // Form Card Container
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.96),
                                  borderRadius: BorderRadius.circular(28),
                                  border: Border.all(
                                    color: const Color(0xFFC3A575).withOpacity(0.35),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F3A20).withOpacity(0.05),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Log In / Sign Up",
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F3A20),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Let's set up your delicious thali delivery.",
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Full Name Field
                                    TextFormField(
                                      controller: _nameController,
                                      keyboardType: TextInputType.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                        color: const Color(0xFF0F3A20),
                                      ),
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          color: Color(0xFF8C7144),
                                        ),
                                        hintText: "Enter Full Name",
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.grey.shade400,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        filled: true,
                                        fillColor: const Color(0xFFFAF8F5),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0F3A20),
                                            width: 1.5,
                                          ),
                                        ),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return "Please enter your full name";
                                        }
                                        if (value.trim().length < 3) {
                                          return "Name must be at least 3 characters";
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 16),

                                    // Phone Number Field
                                    TextFormField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      maxLength: 10,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                        fontSize: 14,
                                        color: const Color(0xFF0F3A20),
                                      ),
                                      decoration: InputDecoration(
                                        prefixIcon: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          margin: const EdgeInsets.only(right: 8),
                                          decoration: BoxDecoration(
                                            border: Border(
                                              right: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            "+91",
                                            style: GoogleFonts.poppins(
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xFF0F3A20),
                                            ),
                                          ),
                                        ),
                                        prefixIconConstraints: const BoxConstraints(
                                          minWidth: 0,
                                          minHeight: 0,
                                        ),
                                        hintText: "Phone Number",
                                        hintStyle: GoogleFonts.poppins(
                                          color: Colors.grey.shade400,
                                          letterSpacing: 0,
                                          fontWeight: FontWeight.normal,
                                        ),
                                        counterText: "",
                                        filled: true,
                                        fillColor: const Color(0xFFFAF8F5),
                                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: BorderSide(color: Colors.grey.shade200),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0F3A20),
                                            width: 1.5,
                                          ),
                                        ),
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

                                    // Verify Button CTA
                                    BlocBuilder<AuthCubit, AuthState>(
                                      builder: (context, state) {
                                        return CustomButton(
                                          text: "Get OTP",
                                          isLoading: state is AuthLoading && state is! AuthOtpSent,
                                          onPressed: _submit,
                                          hasGoldenOutline: true,
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 20),

                                    // OR Divider
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade200,
                                            thickness: 1,
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                          child: Text(
                                            "OR CONTINUE WITH",
                                            style: GoogleFonts.poppins(
                                              color: Colors.grey.shade400,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey.shade200,
                                            thickness: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    // Google Sign-In button
                                    BlocBuilder<AuthCubit, AuthState>(
                                      builder: (context, state) {
                                        return _buildGoogleSignInButton(context, state);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(flex: 4),

                              // Trust Footer
                              const Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.security,
                                      size: 14,
                                      color: Color(0xFF8C7144),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      "100% safe & secure login",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF8C7144),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
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
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
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
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0F3A20)),
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
                              color: Color(0xFF0F3A20),
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
                      Text(
                        "Continue with Google",
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF0F3A20),
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

  void _showQuotaExceededDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Color(0xFFC3A575), size: 28),
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
                    Navigator.pop(dialogContext);
                    context.read<AuthCubit>().signInWithGoogle();
                  },
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text("Log In with Google"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F3A20),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SimpleWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFC3A575)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.1, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.35,
      size.height * 0.1,
      size.width * 0.6,
      size.height * 0.6,
    );
    path.quadraticBezierTo(
      size.width * 0.8,
      size.height * 0.9,
      size.width * 0.9,
      size.height * 0.5,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
