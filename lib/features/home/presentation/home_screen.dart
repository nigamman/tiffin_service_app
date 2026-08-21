import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'menu_cubit.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../tiffin_details/presentation/tiffin_details_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final todayStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<MenuCubit>().loadMenu(),
          color: AppTheme.primaryGreen,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Brand Tagline & Leaf Icon (Location removed)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Kanpur's First Tiffin Service",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.secondaryMarigold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    
                    // Top Right Action Leaf Icon
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, authState) {
                        final isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
                        return GestureDetector(
                          onTap: () {
                            if (isAdmin) {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AdminDashboardScreen(),
                                  ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.eco,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 2. Greeting & Promise Card Side-by-Side (Consistent Outfit Font)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Greetings
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Atithi Bhoj",
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                              height: 1.15,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Ghar jaisa swad, bina kisi jhanjhat ke.",
                            style: GoogleFonts.outfit(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Right Column: Promise Card
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.borderLight, width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.eco_outlined, color: AppTheme.primaryGreen, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Today's Promise",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                    fontFamily: 'Outfit',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Fresh ingredients. No compromise. Just like home.",
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Feature Badges (Outfit Font)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildFeatureBadge(Icons.eco_outlined, "100% Veg"),
                    _buildFeatureBadge(Icons.soup_kitchen_outlined, "Ghar Jaisa Swad"),
                    _buildFeatureBadge(Icons.delivery_dining_outlined, "On Time Delivery"),
                  ],
                ),
                const SizedBox(height: 32),

                // 4. Today's Bhoj Header Block (Outfit Font)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Bhoj",
                          style: GoogleFonts.outfit(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                        Text(
                          todayStr,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 5. Main Special Menu spotlight Card (Outfit Font)
                BlocBuilder<MenuCubit, MenuState>(
                  builder: (context, state) {
                    if (state is MenuLoading) {
                      return Container(
                        height: 300,
                        alignment: Alignment.center,
                        child: const CircularProgressIndicator(color: AppTheme.primaryGreen),
                      );
                    } else if (state is MenuLoaded) {
                      final menu = state.menu;

                      final List<String> mains = menu.items.where((i) => i.contains('Dal') || i.contains('Sabzi') || i.contains('Paneer')).toList();
                      final List<String> breads = menu.items.where((i) => i.contains('Roti') || i.contains('Rice') || i.contains('Paratha')).toList();
                      final List<String> sides = menu.items.where((i) => !mains.contains(i) && !breads.contains(i)).toList();

                      // Price calculations
                      final double regularPrice = menu.price;
                      final double origPrice = regularPrice + 30; // Mock original price
                      final int discountPercent = (((origPrice - regularPrice) / origPrice) * 100).round();

                      return Column(
                        children: [
                          // Highlight Card
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.borderLight, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                // Left details panel
                                Expanded(
                                  flex: 11,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Special\nHome Meal ✨",
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryGreen,
                                          height: 1.15,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        "Wholesome, balanced and cooked with love.",
                                        style: GoogleFonts.outfit(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "₹${regularPrice.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryGreen,
                                              fontFamily: 'Outfit',
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            "₹${origPrice.toStringAsFixed(0)}",
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppTheme.textMuted,
                                              decoration: TextDecoration.lineThrough,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              "$discountPercent% OFF",
                                              style: TextStyle(
                                                color: Colors.green.shade700,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // Right circular bowl image cropping
                                Expanded(
                                  flex: 10,
                                  child: AspectRatio(
                                    aspectRatio: 1,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image: NetworkImage(menu.imageUrl),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 6. Food Category details bar
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.borderLight, width: 0.5),
                            ),
                            child: Row(
                              children: [
                                _buildCategoryColumn("🍲 Mains", mains),
                                _buildVerticalDivider(),
                                _buildCategoryColumn("🫓 Breads", breads),
                                _buildVerticalDivider(),
                                _buildCategoryColumn("🥗 Sides", sides),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // 7. Offer applied indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade100, width: 0.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.local_offer, color: AppTheme.successColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      "FIRSTTIFFIN applied",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.successColor,
                                      ),
                                    ),
                                    Text(
                                      "  •  You save ₹30 on this order",
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        color: AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                const Icon(Icons.check_circle, color: AppTheme.successColor, size: 18),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 8. Swipe to Order Button
                          SwipeOrderButton(
                            text: "Swipe to Order Today's Bhoj",
                            onSwipeCompleted: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TiffinDetailsScreen(menu: menu),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // 9. Social Proof bar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: List.generate(3, (index) {
                                  final avatars = [
                                    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=80',
                                    'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=80',
                                    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=80'
                                  ];
                                  return Align(
                                    widthFactor: 0.6,
                                    child: CircleAvatar(
                                      radius: 9,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 8,
                                        backgroundImage: NetworkImage(avatars[index]),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Loved by 1,200+ customers in Kanpur",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(Icons.star, color: Colors.orange, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                "4.8",
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              Text(
                                " (230+ reviews)",
                                style: GoogleFonts.outfit(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    } else if (state is MenuError) {
                      return Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Oops! ${state.message}"),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.read<MenuCubit>().loadMenu(),
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryGreen, size: 16),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 0.5,
      color: AppTheme.borderLight,
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }

  Widget _buildCategoryColumn(String categoryName, List<String> dishes) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryName,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
              fontFamily: 'Outfit',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dishes.isNotEmpty ? dishes.join('\n') : '-',
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: AppTheme.textDark,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// Premium Slide/Swipe to Order Confirmation Button with Animating Chevrons
class SwipeOrderButton extends StatefulWidget {
  final VoidCallback onSwipeCompleted;
  final String text;

  const SwipeOrderButton({
    Key? key,
    required this.onSwipeCompleted,
    this.text = "Swipe to Order Today's Bhoj",
  }) : super(key: key);

  @override
  State<SwipeOrderButton> createState() => _SwipeOrderButtonState();
}

class _SwipeOrderButtonState extends State<SwipeOrderButton> with TickerProviderStateMixin {
  double _dragPercent = 0.0;
  late AnimationController _controller;
  late AnimationController _arrowController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_controller);

    // Continuous marquee flow animation for chevron arrows
    _arrowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _arrowController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDragWidth) {
    setState(() {
      _dragPercent += details.primaryDelta! / maxDragWidth;
      _dragPercent = _dragPercent.clamp(0.0, 1.0);
    });
  }

  void _onDragEnd() {
    if (_dragPercent > 0.85) {
      widget.onSwipeCompleted();
      setState(() {
        _dragPercent = 1.0;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _animateTo(0.0);
        }
      });
    } else {
      _animateTo(0.0);
    }
  }

  void _animateTo(double target) {
    _slideAnimation = Tween<double>(
      begin: _dragPercent,
      end: target,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    
    _controller.forward(from: 0.0).then((_) {
      setState(() {
        _dragPercent = target;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double buttonHeight = 56.0;
        const double handleSize = 44.0;
        final double maxDragWidth = constraints.maxWidth - handleSize - 12.0;

        final double currentOffset = _controller.isAnimating 
            ? _slideAnimation.value * maxDragWidth 
            : _dragPercent * maxDragWidth;

        return Container(
          width: double.infinity,
          height: buttonHeight,
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(buttonHeight / 2),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Sliding prompt text
              Align(
                alignment: Alignment.center,
                child: Opacity(
                  opacity: (1.0 - _dragPercent * 1.5).clamp(0.1, 1.0),
                  child: Text(
                    widget.text,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              // Chevron arrows indicating swipe direction (Marquee flow wave)
              Positioned(
                right: 24,
                child: Opacity(
                  opacity: (1.0 - _dragPercent * 2.0).clamp(0.0, 1.0),
                  child: AnimatedBuilder(
                    animation: _arrowController,
                    builder: (context, child) {
                      return Row(
                        children: List.generate(3, (index) {
                          // Computes forward marquee opacity shift
                          final double delayFraction = index * 0.25;
                          double val = (_arrowController.value - delayFraction) % 1.0;
                          double opacity = (1.0 - (val - 0.5).abs() * 3.0).clamp(0.15, 1.0);
                          
                          return Icon(
                            Icons.chevron_right,
                            color: Colors.white.withOpacity(opacity),
                            size: 16,
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),

              // Draggable white handle
              Positioned(
                left: currentOffset,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDragWidth),
                  onHorizontalDragEnd: (details) => _onDragEnd(),
                  child: Container(
                    width: handleSize,
                    height: handleSize,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
