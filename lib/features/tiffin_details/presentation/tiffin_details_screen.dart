import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../home/data/menu_repository.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/presentation/login_screen.dart';
import '../../booking/presentation/booking_flow_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class TiffinDetailsScreen extends StatelessWidget {
  final MenuModel menu;

  const TiffinDetailsScreen({Key? key, required this.menu}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Categorize items dynamically
    final List<String> mainDishes = menu.items.where((i) => i.contains('Dal') || i.contains('Sabzi') || i.contains('Paneer')).toList();
    final List<String> breads = menu.items.where((i) => i.contains('Roti') || i.contains('Rice') || i.contains('Paratha')).toList();
    final List<String> sides = menu.items.where((i) => !mainDishes.contains(i) && !breads.contains(i)).toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Stack(
        children: [
          // Parallax Custom Scroll View
          CustomScrollView(
            slivers: [
              // Parallax header image
              SliverAppBar(
                expandedHeight: 280,
                pinned: true,
                backgroundColor: AppTheme.backgroundLight,
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppTheme.textDark, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        menu.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: AppTheme.borderLight,
                          child: const Icon(Icons.fastfood, size: 80, color: AppTheme.textMuted),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black38, Colors.transparent],
                            begin: Alignment.topCenter,
                            end: Alignment.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Details
              SliverPadding(
                padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 100),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Title and price row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Home Feast",
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGreen,
                                      fontSize: 26,
                                      letterSpacing: -0.5,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                "Pure Vegetarian • Home Cooked",
                                style: TextStyle(
                                  color: AppTheme.secondaryMarigold,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "₹${menu.price.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                                fontFamily: 'Outfit',
                              ),
                            ),
                            const Text(
                              "Per meal",
                              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderLight, height: 1),
                    const SizedBox(height: 24),

                    // Box contents
                    const Text(
                      "What's in the Box",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                        fontFamily: 'Outfit',
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (mainDishes.isNotEmpty)
                      _buildItemsBlock("Mains", mainDishes, Icons.soup_kitchen_outlined),
                    if (breads.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildItemsBlock("Breads & Rice", breads, Icons.rice_bowl_outlined),
                    ],
                    if (sides.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildItemsBlock("Accompaniments", sides, Icons.restaurant_menu_outlined),
                    ],

                    const SizedBox(height: 24),
                    const Divider(color: AppTheme.borderLight, height: 1),
                    const SizedBox(height: 24),

                    // Portions / Details Section
                    _buildCuratedInfoTile(
                      icon: Icons.face_retouching_natural_outlined,
                      title: "Serves 1 Person",
                      subtitle: "Generous Indian meal portions cooked in small batches.",
                    ),
                    const SizedBox(height: 14),
                    _buildCuratedInfoTile(
                      icon: Icons.shield_outlined,
                      title: "100% Hygienic Packaging",
                      subtitle: "Prepared in sterile kitchens, packed in food-grade hot cases.",
                    ),
                    const SizedBox(height: 14),
                    _buildCuratedInfoTile(
                      icon: Icons.access_time_outlined,
                      title: "Delivery Slots",
                      subtitle: "Lunch (12:00 PM - 2:00 PM) or Dinner (7:00 PM - 9:00 PM).",
                    ),
                  ]),
                ),
              ),
            ],
          ),

          // Floating Sticky Bottom Action Bar with Blur Filter
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    border: const Border(
                      top: BorderSide(color: AppTheme.borderLight, width: 0.8),
                    ),
                  ),
                  child: BlocBuilder<AuthCubit, AuthState>(
                    builder: (context, authState) {
                      return CustomButton(
                        text: "Continue to Booking",
                        icon: Icons.arrow_forward_outlined,
                        onPressed: () {
                          if (authState is AuthAuthenticated) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingFlowScreen(menu: menu),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Please sign in to configure booking")),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsBlock(String title, List<String> items, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppTheme.primaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryGreen,
                  fontFamily: 'Outfit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontFamily: 'PlusJakartaSans'),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCuratedInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppTheme.primaryGreen),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppTheme.textDark,
                  fontFamily: 'Outfit',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.3,
                  fontFamily: 'PlusJakartaSans',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
