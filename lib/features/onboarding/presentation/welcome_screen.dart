import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../home/presentation/main_layout.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3EC), // Exact cream base matching the background image
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/img/onboarding_bg.jpg'),
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter, // Keeps the table, tiffin box, and dal bowl anchored perfectly at the bottom
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * (isSmallScreen ? 0.01 : 0.03)), // Dynamic top margin to prevent collision with notch
                          
                          // 1. Top Brand Header Section (Sits in the clean cream area)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Thin Ornate Arch Logo representation
                                Column(
                                  children: [
                                    const Icon(
                                      Icons.spa, // Lotus ornament
                                      color: Color(0xFFC3A575),
                                      size: 16,
                                    ),
                                    const SizedBox(height: 2),
                                    Container(
                                      width: 58,
                                      height: 62,
                                      decoration: BoxDecoration(
                                        border: Border.all(color: const Color(0xFFC3A575), width: 1.0),
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(29),
                                          topRight: Radius.circular(29),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF0F3A20).withOpacity(0.04),
                                          shape: BoxShape.circle,
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: const Icon(
                                          Icons.backpack_outlined, // Stylized tiffin carrier layers
                                          color: Color(0xFF0F3A20),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                
                                // Editorial high-contrast Serif headers (Matches mockup typography feeling)
                                Text(
                                  "Atithi",
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 36 : 44, // Safe sizing to prevent wrapping/overflow
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F3A20),
                                    height: 0.9,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                Text(
                                  "Bhoj",
                                  style: GoogleFonts.poppins(
                                    fontSize: isSmallScreen ? 36 : 44,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFC3A575),
                                    height: 1.0,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                                const SizedBox(height: 10),
          
                                // TIFFIN SERVICE text with top and bottom ornate diamond dividers
                                _buildOrnateDivider(),
                                const SizedBox(height: 5),
                                Text(
                                  "TIFFIN SERVICE",
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 3.5,
                                    color: const Color(0xFF0F3A20),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _buildOrnateDivider(),
                                
                                const SizedBox(height: 16),
                                
                                // Tagline description
                                Text(
                                  "Ghar jaisa swad,\nbina kisi jhanjhat ke.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B583E),
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _buildOrnateDivider(),
                              ],
                            ),
                          ),
          
                          const Spacer(),
          
                          // 2. Bottom Actions Section (Overlays beautifully on top of the wooden table)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Namaste, Chaliye Shuru Karein Button with gold arrow circle badge
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0F3A20).withOpacity(0.2),
                                      blurRadius: 15,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const MainLayout(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F3A20),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const SizedBox(width: 32),
                                      Text(
                                        "Namaste, Chaliye Shuru Karein",
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFC3A575),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: Color(0xFF0F3A20),
                                          size: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
          
                              const SizedBox(height: 28),
          
                              // Feature details badges row separated by thin line dividers
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildFeatureBadge(Icons.home_work_outlined, "FRESHLY\nCOOKED"),
                                  _buildVerticalDivider(),
                                  _buildFeatureBadge(Icons.shield_outlined, "HYGIENIC\n& SAFE"),
                                  _buildVerticalDivider(),
                                  _buildFeatureBadge(Icons.delivery_dining_outlined, "ON TIME\nDELIVERY"),
                                ],
                              ),
                              const SizedBox(height: 12),
                            ],
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

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 22, color: const Color(0xFFC3A575)),
        const SizedBox(height: 6),
        Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppTheme.textMuted,
            height: 1.25,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 0.8,
      height: 32,
      color: const Color(0xFFEDE8E0),
    );
  }

  Widget _buildOrnateDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 0.8,
          color: const Color(0xFFC3A575).withOpacity(0.5),
        ),
        const SizedBox(width: 5),
        Container(
          width: 3.5,
          height: 3.5,
          transform: Matrix4.rotationZ(0.785), // Rotate 45deg to render diamond
          color: const Color(0xFFC3A575),
        ),
        const SizedBox(width: 5),
        Container(
          width: 32,
          height: 0.8,
          color: const Color(0xFFC3A575).withOpacity(0.5),
        ),
      ],
    );
  }
}
