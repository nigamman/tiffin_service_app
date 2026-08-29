import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../home/data/menu_repository.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/login_screen.dart';
import '../../booking/presentation/booking_flow_screen.dart';
import '../../../core/theme/app_theme.dart';

class TiffinDetailsScreen extends StatefulWidget {
  final MenuModel menu;
  final String initialSlot;

  const TiffinDetailsScreen({
    Key? key,
    required this.menu,
    this.initialSlot = 'lunch',
  }) : super(key: key);

  @override
  State<TiffinDetailsScreen> createState() => _TiffinDetailsScreenState();
}

class _TiffinDetailsScreenState extends State<TiffinDetailsScreen> {
  int _quantity = 1;
  bool _isFavorite = false;

  void _increment() {
    setState(() {
      _quantity++;
    });
  }

  void _decrement() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2), // Premium warm cream background
      body: Stack(
        children: [
          // Giant subtle decorative watermark in the top-right background
          Positioned(
            top: -120,
            right: -120,
            child: SvgPicture.asset(
              'assets/img/Atithi_Bhoj_Subtle_Mandala_Watermark.svg',
              width: 320,
              height: 320,
              colorFilter: ColorFilter.mode(
                const Color(0xFFEADFC9).withOpacity(0.09),
                BlendMode.srcIn,
              ),
            ),
          ),
          // Subtle watermark in the bottom-left background
          Positioned(
            bottom: 40,
            left: -140,
            child: SvgPicture.asset(
              'assets/img/Atithi_Bhoj_Subtle_Mandala_Watermark.svg',
              width: 360,
              height: 360,
              colorFilter: ColorFilter.mode(
                const Color(0xFFEADFC9).withOpacity(0.06),
                BlendMode.srcIn,
              ),
            ),
          ),
          SafeArea(
            top: true,
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _header(context),
                  _heroSection(context),
                  _descriptionSection(),
                  _ingredientsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomCart(),
    );
  }

  // --- Premium Modern Header Row ---
  Widget _header(BuildContext context) {
    final titleLabel = widget.initialSlot == 'lunch' ? 'Lunch' : 'Dinner';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          // Circular Back Button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Color(0xFF0B4828),
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Text(
            "Today's $titleLabel",
            style: GoogleFonts.poppins(
              color: const Color(0xFF222222),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          // Favorite Button
          GestureDetector(
            onTap: () {
              setState(() {
                _isFavorite = !_isFavorite;
              });
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : const Color(0xFF0B4828),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share Button
          GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Link copied! Share Atithi Bhoj with your friends.")),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.share_outlined,
                color: Color(0xFF0B4828),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modern Highlight Chips & Description ---
  Widget _descriptionSection() {
    final isLunch = widget.initialSlot == 'lunch';
    final descriptionText = isLunch
        ? "A nutritious, balanced North Indian lunch prepared fresh daily. Made with premium quality ingredients, minimal oil, and spices that feel light on the stomach."
        : "A wholesome, comforting dinner thali featuring premium Paneer/Veg specialities, fresh rotis, rice, and delicious sides. Sealed hot and delivered fresh.";

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Highlights Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildHighlightChip(Icons.stars_outlined, "Homestyle"),
                const SizedBox(width: 8),
                _buildHighlightChip(Icons.local_fire_department_outlined, "Mild Spice"),
                const SizedBox(width: 8),
                _buildHighlightChip(Icons.favorite_border, "Low Oil"),
                const SizedBox(width: 8),
                _buildHighlightChip(Icons.eco_outlined, "100% Veg"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Description text
          Text(
            descriptionText,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0B4828).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF0B4828)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0B4828),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modern Minimalist Food Card Section ---
  Widget _heroSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Rounded Rectangle Image Card with deep soft shadow
          Container(
            height: 280,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9F7F2), // Matches screen background to blend seamlessly
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8C7144).withOpacity(0.15), // Premium gold-bronze glow
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Padding(
                padding: const EdgeInsets.all(8.0), // Adds breathing room to prevent cutting
                child: widget.initialSlot == 'lunch'
                    ? Image.asset(
                        'assets/img/lunch_plate.png',
                        fit: BoxFit.contain, // Keeps entire plate visible
                      )
                    : Image.network(
                        widget.menu.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: const Color(0xFFF5EFE3),
                          child: const Icon(
                            Icons.restaurant,
                            color: Color(0xFFD3B16A),
                            size: 80,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          // Floating Green Gradient Pill Badge with verification checkmark
          Positioned(
            bottom: -16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0B4828),
                    Color(0xFF1E5631),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B4828).withOpacity(0.22),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    color: Color(0xFFEADFC9), // warm gold/cream tint
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'WHOLESOME & BALANCED',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Modern Grid-based Food Cards Section ---
  Widget _ingredientsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            "What's in your thali?",
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 16),
          // Grid layout
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: widget.menu.items.length,
            itemBuilder: (context, index) {
              return _buildFoodCard(widget.menu.items[index]);
            },
          ),
        ],
      ),
    );
  }

  IconData _getIngredientIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dal') || lower.contains('curry') || lower.contains('shorba') || lower.contains('soup')) {
      return Icons.soup_kitchen_outlined;
    } else if (lower.contains('roti') || lower.contains('phulka') || lower.contains('naan') || lower.contains('paratha') || lower.contains('bread')) {
      return Icons.bakery_dining_outlined;
    } else if (lower.contains('rice') || lower.contains('pulao') || lower.contains('biryani') || lower.contains('chawal')) {
      return Icons.rice_bowl_outlined;
    } else if (lower.contains('salad')) {
      return Icons.spa_outlined;
    } else if (lower.contains('pickle') || lower.contains('achar') || lower.contains('chutney')) {
      return Icons.restaurant_menu_outlined;
    } else if (lower.contains('rayta') || lower.contains('raita') || lower.contains('dahi') || lower.contains('curd') || lower.contains('lassi')) {
      return Icons.local_cafe_outlined;
    } else if (lower.contains('paneer') || lower.contains('sabzi') || lower.contains('veg') || lower.contains('jhalfrezi') || lower.contains('kofta')) {
      return Icons.dinner_dining_outlined;
    }
    return Icons.eco_outlined;
  }

  _ChipStyle _getChipStyle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dal') || lower.contains('curry') || lower.contains('shorba') || lower.contains('soup')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFE5D5BA),
        textColor: Color(0xFF8C7040),
      );
    }
    if (lower.contains('roti') || lower.contains('phulka') || lower.contains('naan') || lower.contains('paratha') || lower.contains('bread')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFDCD0BF),
        textColor: Color(0xFF7A644A),
      );
    }
    if (lower.contains('rice') || lower.contains('pulao') || lower.contains('biryani') || lower.contains('chawal')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFC7D7E5),
        textColor: Color(0xFF4A6A80),
      );
    }
    if (lower.contains('salad')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFC4DCCB),
        textColor: Color(0xFF2C6A35),
      );
    }
    if (lower.contains('pickle') || lower.contains('achar') || lower.contains('chutney')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFF7C8BC),
        textColor: Color(0xFFAD3820),
      );
    }
    if (lower.contains('rayta') || lower.contains('raita') || lower.contains('dahi') || lower.contains('curd') || lower.contains('lassi')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFC2D9E0),
        textColor: Color(0xFF3B7280),
      );
    }
    if (lower.contains('paneer') || lower.contains('sabzi') || lower.contains('veg') || lower.contains('jhalfrezi') || lower.contains('kofta')) {
      return const _ChipStyle(
        bgColor: Colors.white,
        borderColor: Color(0xFFE5CEB6),
        textColor: Color(0xFF9E641A),
      );
    }
    return _ChipStyle(
      bgColor: Colors.white,
      borderColor: const Color(0xFF0B4828).withOpacity(0.18),
      textColor: const Color(0xFF0B4828),
    );
  }

  String _getFoodSubtitle(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('dal')) return "Slow-cooked ghee tadka";
    if (lower.contains('roti') || lower.contains('phulka') || lower.contains('naan') || lower.contains('bread') || lower.contains('paratha')) {
      return "4 fresh tawa pieces";
    }
    if (lower.contains('rice') || lower.contains('pulao') || lower.contains('biryani') || lower.contains('chawal')) {
      return "Aromatic basmati rice";
    }
    if (lower.contains('salad')) return "Crisp fresh veggies";
    if (lower.contains('pickle') || lower.contains('achar')) return "Tangy homemade recipe";
    if (lower.contains('rayta') || lower.contains('raita') || lower.contains('dahi') || lower.contains('curd')) {
      return "Cool cumin yogurt cup";
    }
    if (lower.contains('paneer')) return "Soft rich cottage cheese";
    if (lower.contains('sabzi') || lower.contains('veg') || lower.contains('jhalfrezi')) {
      return "Nutritious seasonal veg";
    }
    return "Portion serving";
  }

  Widget _buildFoodCard(String name) {
    final lower = name.toLowerCase();
    final isDal = lower.contains('dal');
    final isVeg = lower.contains('veg') || lower.contains('sabzi') || lower.contains('jhalfrezi') || lower.contains('paneer');
    final isRoti = lower.contains('roti') || lower.contains('phulka') || lower.contains('naan') || lower.contains('paratha') || lower.contains('bread');
    final isRice = lower.contains('rice') || lower.contains('pulao') || lower.contains('biryani') || lower.contains('chawal');
    final isSalad = lower.contains('salad');
    final isPickle = lower.contains('pickle') || lower.contains('achar') || lower.contains('chutney');
    
    final style = _getChipStyle(name);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Veg Dot Indicator in Top Right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0B4828), width: 1),
                borderRadius: BorderRadius.circular(3),
              ),
              child: const Icon(
                Icons.circle,
                size: 6,
                color: Color(0xFF0B4828),
              ),
            ),
          ),
          // Card Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isDal)
                  Image.asset(
                    'assets/icons/dal-icon.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  )
                else if (isVeg)
                  Image.asset(
                    'assets/icons/mix-veg.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  )
                else if (isRoti)
                  Image.asset(
                    'assets/icons/roti.png',
                    width: 64, // Sized larger to balance transparent padding
                    height: 64,
                    fit: BoxFit.contain,
                  )
                else if (isRice)
                  Image.asset(
                    'assets/icons/rice.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  )
                else if (isSalad)
                  Image.asset(
                    'assets/icons/salad.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  )
                else if (isPickle)
                  Image.asset(
                    'assets/icons/pickle.png',
                    width: 56,
                    height: 56,
                    fit: BoxFit.contain,
                  )
                else
                  Icon(
                    _getIngredientIcon(name),
                    size: 40,
                    color: style.textColor,
                  ),
                const SizedBox(height: 8),
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF222222),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFoodSubtitle(name),
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleBooking(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final double timeOfDay = hour + (minute / 60.0);

    // Lunch cutoff: 9:30 AM (9.5)
    // Dinner cutoff: 5:00 PM (17.0)

    String finalSlot = widget.initialSlot;
    DateTime startDate = DateTime.now(); // Default to today!
    bool showNoonPopup = false;
    bool showNightPopup = false;

    if (widget.initialSlot == 'lunch') {
      if (timeOfDay >= 9.5 && timeOfDay < 17.0) {
        // Noon booking: Lunch is selected, but lunch cutoff passed, dinner is open.
        // Change slot to dinner and show popup!
        finalSlot = 'dinner';
        startDate = DateTime.now(); // Deliver tonight
        showNoonPopup = true;
      } else if (timeOfDay >= 17.0) {
        // Night booking: cutoffs passed. Start tomorrow!
        startDate = DateTime.now().add(const Duration(days: 1));
        showNightPopup = true;
      }
    } else {
      // Dinner is selected
      if (timeOfDay >= 17.0) {
        // Night booking: Dinner cutoff passed. Start tomorrow!
        startDate = DateTime.now().add(const Duration(days: 1));
        showNightPopup = true;
      }
    }

    if (showNoonPopup) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Lunch Cutoff Passed",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF222222),
            ),
          ),
          content: Text(
            "Today's Lunch cutoff (9:30 AM) has passed. Your tiffin will be delivered tonight for Dinner (7:00 PM - 9:00 PM) instead.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToBookingFlow(context, finalSlot, startDate);
              },
              child: Text(
                "Proceed",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B4828),
                ),
              ),
            ),
          ],
        ),
      );
    } else if (showNightPopup) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Order Starts Tomorrow",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF222222),
            ),
          ),
          content: Text(
            "Today's delivery cutoffs have passed. Your warm fresh tiffin will be scheduled and delivered starting tomorrow.",
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _navigateToBookingFlow(context, finalSlot, startDate);
              },
              child: Text(
                "Proceed",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0B4828),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      _navigateToBookingFlow(context, finalSlot, startDate);
    }
  }

  void _navigateToBookingFlow(BuildContext context, String slot, DateTime startDate) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingFlowScreen(
          menu: widget.menu,
          initialSlot: slot,
          initialStartDate: startDate,
          initialQuantity: _quantity,
        ),
      ),
    );
  }

  Widget _bottomCart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Price Tag
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '₹${(widget.menu.price * _quantity).toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0B4828),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Per Thali',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Modern Quantity Selector Capsule
            _quantitySelector(),
            const SizedBox(width: 8),
            // Checkout Button
            Expanded(
              child: SizedBox(
                height: 48,
                child: BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, authState) {
                    return ElevatedButton(
                      onPressed: () {
                        if (authState is AuthAuthenticated) {
                          _handleBooking(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please sign in to continue booking.")),
                          );
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B4828),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Add to Cart',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dynamic Quantity Selector Row ---
  Widget _quantitySelector() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF9F7F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: _decrement,
            icon: const Icon(Icons.remove, size: 16, color: Color(0xFF262626)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          Text(
            '$_quantity',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: const Color(0xFF262626),
            ),
          ),
          IconButton(
            onPressed: _increment,
            icon: const Icon(Icons.add, size: 16, color: Color(0xFF262626)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}

class _ChipStyle {
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const _ChipStyle({
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });
}
