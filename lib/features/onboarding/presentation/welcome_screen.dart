import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../home/presentation/main_layout.dart';

// ─────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — matches your established Atithi Bhoj system
// ─────────────────────────────────────────────────────────────────────────
class AtithiColors {
  static const deepMaroon = Color(0xFF5C1A1B);
  static const chiliRed = Color(0xFFC0392B);
  static const turmericGold = Color(0xFFC3A575); // Border gold
  static const textGold = Color(0xFF8C7144);      // Text gold/brown
  static const curryGreen = Color(0xFF0F3A20);    // Brand deep green
  static const warmCream = Color(0xFFF7EFDD);
  static const cream = Color(0xFFF7F4EB);
  static const ink = Color(0xFF0F3A20);
}

class AtithiText {
  static TextStyle display({double size = 42, Color? color}) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: color ?? AtithiColors.curryGreen,
        letterSpacing: -0.5,
      );

  static TextStyle tagline({double size = 14, Color? color}) => GoogleFonts.poppins(
        fontSize: size,
        fontStyle: FontStyle.italic,
        fontWeight: FontWeight.w600,
        color: color ?? AtithiColors.curryGreen,
      );

  static TextStyle eyebrow({double size = 9, Color? color}) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: color ?? AtithiColors.deepMaroon,
      );

  static TextStyle button({double size = 11, Color? color}) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: color ?? AtithiColors.turmericGold,
      );
}

// ─────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    this.onUnlocked,
  });

  /// Called once the user completes the slide gesture.
  final VoidCallback? onUnlocked;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: AtithiColors.cream,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Grayscale Kanpur monument watermark centered near the bottom
          Positioned(
            bottom: size.height * 0.08,
            left: 0,
            right: 0,
            height: size.height * 0.56,
            child: SvgPicture.asset(
              'assets/welcome_page/bg_mon2.svg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
          ),

          // Corner mandalas
          Positioned(
            top: 0,
            left: 0,
            width: size.width * 0.45,
            child: Image.asset(
              'assets/welcome_page/bg2_topleft.png',
              fit: BoxFit.contain,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            width: size.width * 0.45,
            child: Image.asset(
              'assets/welcome_page/bg3_topright.png',
              fit: BoxFit.contain,
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: size.height * (isSmallScreen ? 0.04 : 0.06)),
                        const _BrandMark(), // 1
                        const SizedBox(height: 10),
                        Center(
                          child: Image.asset(
                            'assets/welcome_page/bg5_line.png', // 5
                            width: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Atithi Bhoj', // 3
                          style: AtithiText.display(size: isSmallScreen ? 38 : 46),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        const Center(
                          child: GoldWaveUnderliner(), // 4
                        ),
                        const SizedBox(height: 14),
                        Text(
                          "KANPUR'S FIRST TIFFIN SERVICE APP", // 2
                          style: AtithiText.eyebrow(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Ghar jaisa swaad, har roz aapke saath.', // 6
                          style: AtithiText.tagline(size: isSmallScreen ? 14 : 16),
                          textAlign: TextAlign.center,
                        ),
                        
                        const Spacer(flex: 5),
                        
                        // Premium Feature Card Box
                        const _FeatureCardBox(),
                        
                        const Spacer(flex: 1),
                        
                        // Slide to Open button
                        SlideToOpenButton(
                          label: 'SLIDE RIGHT TO OPEN',
                          onUnlocked: () {
                            if (onUnlocked != null) {
                              onUnlocked!();
                            } else {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (!context.mounted) return;
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const MainLayout(),
                                  ),
                                );
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// BRAND MARK — loads the official application icon
// ─────────────────────────────────────────────────────────────────────────
class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          'assets/icons/atithibhoj_appicon.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// FEATURE CARD BOX (3 columns with vertical gold dividers)
// ─────────────────────────────────────────────────────────────────────────
class _FeatureCardBox extends StatelessWidget {
  const _FeatureCardBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6EE).withOpacity(0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AtithiColors.turmericGold.withOpacity(0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildFeatureItem(
              iconWidget: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.home_outlined,
                    color: AtithiColors.textGold,
                    size: 28,
                  ),
                  Positioned(
                    bottom: 9,
                    child: Container(
                      width: 8,
                      height: 8,
                      color: const Color(0xFFF3EDE0), // mask the door line of home_outlined
                    ),
                  ),
                  const Positioned(
                    bottom: 8,
                    child: Icon(
                      Icons.favorite,
                      color: AtithiColors.textGold,
                      size: 10,
                    ),
                  ),
                ],
              ),
              label: 'GHAR JAISA\nSWAAD',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildFeatureItem(
              iconWidget: const Icon(
                Icons.spa,
                color: AtithiColors.curryGreen,
                size: 26,
              ),
              label: 'FRESH &\nHYGIENIC',
            ),
          ),
          _buildDivider(),
          Expanded(
            child: _buildFeatureItem(
              iconWidget: const Icon(
                Icons.access_time_filled_rounded,
                color: AtithiColors.curryGreen,
                size: 26,
              ),
              label: 'TIMELY\nDELIVERY',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 60,
      color: AtithiColors.turmericGold.withOpacity(0.3),
    );
  }

  Widget _buildFeatureItem({
    required Widget iconWidget,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AtithiColors.turmericGold.withOpacity(0.4),
              width: 1.2,
            ),
            color: const Color(0xFFF3EDE0), // Light cream/gold background
          ),
          alignment: Alignment.center,
          child: iconWidget,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AtithiColors.curryGreen,
            letterSpacing: 0.5,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Image.asset(
          'assets/welcome_page/bg5_line.png',
          width: 32,
          fit: BoxFit.contain,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SLIDE TO OPEN — draggable gesture
// ─────────────────────────────────────────────────────────────────────────
class SlideToOpenButton extends StatefulWidget {
  const SlideToOpenButton({
    super.key,
    required this.onUnlocked,
    required this.label,
    this.height = 64,
  });

  final VoidCallback onUnlocked;
  final String label;
  final double height;

  @override
  State<SlideToOpenButton> createState() => _SlideToOpenButtonState();
}

class _SlideToOpenButtonState extends State<SlideToOpenButton> with SingleTickerProviderStateMixin {
  double _dragExtent = 0; // 0..1
  bool _unlocked = false;
  late final AnimationController _resetController;
  late Animation<double> _resetAnim;

  @override
  void initState() {
    super.initState();
    _resetController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..addListener(() {
        setState(() => _dragExtent = _resetAnim.value);
      });
    _resetAnim = Tween<double>(begin: 0, end: 0).animate(_resetController);
  }

  void _animateResetTo(double from, double to) {
    _resetAnim = Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _resetController, curve: Curves.easeOutCubic),
    );
    _resetController.forward(from: 0);
  }

  @override
  void dispose() {
    _resetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double knobSize = widget.height - 8;

    return Center(
      child: GestureDetector(
        onHorizontalDragUpdate: _unlocked
            ? null
            : (details) {
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box == null || !box.hasSize) return;
                final double width = box.size.width;
                final double travel = width - knobSize - 8;
                if (travel <= 0) return;
                setState(() {
                  _dragExtent = ((_dragExtent * travel) + details.delta.dx).clamp(0.0, travel) / travel;
                });
              },
        onHorizontalDragEnd: _unlocked
            ? null
            : (details) {
                if (_dragExtent > 0.82) {
                  setState(() {
                    _unlocked = true;
                    _dragExtent = 1;
                  });
                  widget.onUnlocked();
                } else {
                  _animateResetTo(_dragExtent, 0);
                }
              },
        child: Container(
          height: widget.height,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF0C2F19),
                Color(0xFF0F3A20),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(widget.height / 2),
            border: Border.all(color: AtithiColors.turmericGold, width: 2),
            boxShadow: [
              BoxShadow(
                color: AtithiColors.curryGreen.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Decorative underliner elements faintly visible on the right
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Opacity(
                  opacity: 0.15,
                  child: Image.asset(
                    'assets/welcome_page/bg4_underliner.png',
                    width: 60,
                    fit: BoxFit.contain,
                    color: AtithiColors.turmericGold,
                  ),
                ),
              ),
              
              // Label — fades slightly as the knob passes over it
              Center(
                child: Opacity(
                  opacity: (1 - _dragExtent * 1.4).clamp(0.0, 1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Small gold branch flourish (using the underliner asset shrunk)
                      Image.asset(
                        'assets/welcome_page/bg4_underliner.png',
                        height: 16,
                        width: 32,
                        fit: BoxFit.contain,
                        color: AtithiColors.turmericGold,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Draggable knob aligned fractionally
              Align(
                alignment: Alignment(-1.0 + (_dragExtent * 2.0), 0.0),
                child: Container(
                  width: knobSize,
                  height: knobSize,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFAF6EE),
                        Color(0xFFEFE8D4),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: AtithiColors.turmericGold, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.keyboard_double_arrow_right_rounded,
                      color: AtithiColors.curryGreen,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// CUSTOM GOLD WAVE UNDERLINER
// ─────────────────────────────────────────────────────────────────────────
class GoldWaveUnderliner extends StatelessWidget {
  const GoldWaveUnderliner({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(180, 16),
      painter: _WavePainter(),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AtithiColors.turmericGold.withOpacity(0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    // A nice wave starting from left to right
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

    // Draw the leaf flourish at the right end of the wave
    final leafPaint = Paint()
      ..color = AtithiColors.turmericGold
      ..style = PaintingStyle.fill;

    // Small leaf shape (a diamond/oval rotated)
    final leafCenter = Offset(size.width * 0.92, size.height * 0.5);
    final leafPath = Path();
    leafPath.moveTo(leafCenter.dx, leafCenter.dy - 3);
    leafPath.quadraticBezierTo(leafCenter.dx + 4, leafCenter.dy - 3, leafCenter.dx + 6, leafCenter.dy);
    leafPath.quadraticBezierTo(leafCenter.dx + 4, leafCenter.dy + 3, leafCenter.dx, leafCenter.dy + 3);
    leafPath.quadraticBezierTo(leafCenter.dx - 4, leafCenter.dy + 3, leafCenter.dx - 6, leafCenter.dy);
    leafPath.quadraticBezierTo(leafCenter.dx - 4, leafCenter.dy - 3, leafCenter.dx, leafCenter.dy - 3);
    leafPath.close();

    canvas.drawPath(leafPath, leafPaint);

    // A tiny gold dot next to the leaf
    canvas.drawCircle(Offset(size.width * 0.96, size.height * 0.5), 1.5, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

