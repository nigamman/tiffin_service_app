import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/services/firebase_service.dart';
import 'menu_cubit.dart';
import '../data/menu_repository.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../tiffin_details/presentation/tiffin_details_screen.dart';
import '../../booking/presentation/booking_flow_screen.dart';
import '../../orders/presentation/orders_cubit.dart';
import '../../orders/presentation/subscription_details_screen.dart';
import '../../admin/presentation/admin_dashboard_screen.dart';
import '../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    // Dispatch loading of menu and user orders at startup
    context.read<MenuCubit>().loadMenu();
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<OrdersCubit>().loadOrders();
    }
    
    // Start periodic countdown timer (rebuilds every minute to update remaining times)
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  String _getCutoffCountdown(bool isLunch) {
    final now = DateTime.now();
    
    // Lunch cutoff: 9:30 AM today
    // Dinner cutoff: 5:00 PM today
    final int cutoffHour = isLunch ? 9 : 17;
    final int cutoffMinute = isLunch ? 30 : 0;
    
    final cutoffTime = DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);
    
    if (now.isAfter(cutoffTime)) {
      return "Closed for Today";
    }
    
    final difference = cutoffTime.difference(now);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    
    if (hours > 0) {
      return "Closes in ${hours}h ${minutes}m";
    } else {
      return "Closes in ${minutes}m";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F6), // Warm cream background matching design
      body: SafeArea(
        child: BlocBuilder<MenuCubit, MenuState>(
          builder: (context, menuState) {
            return RefreshIndicator(
              onRefresh: () async {
                context.read<MenuCubit>().loadMenu();
                final authState = context.read<AuthCubit>().state;
                if (authState is AuthAuthenticated) {
                  context.read<OrdersCubit>().loadOrders();
                }
              },
              color: AppTheme.primaryGreen,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Header Row (Greeting, Drawer Icon, Notification)
                    _buildHeader(context),
                    const SizedBox(height: 20),

                    // 2. Aaj Ka Swad Green Banner Card
                    _buildBannerCard(),
                    const SizedBox(height: 24),

                    // 3. Order for Today Section (Lunch & Dinner Cards)
                    _buildOrderTodaySection(context, menuState),
                    const SizedBox(height: 24),

                    // 4. Your Subscription Section
                    _buildSubscriptionSection(context),
                    const SizedBox(height: 20),

                    // 5. Promo Coupon Card
                    _buildPromoCard(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Header ---
  Widget _buildHeader(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final bool isAdmin = authState is AuthAuthenticated && authState.user.isAdmin;
        final String? userPhone = authState is AuthAuthenticated ? authState.user.phone : null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Branded App Title Logo on the left
            Text(
              "Atithi Bhoj",
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0B4828), // Premium Emerald green
                letterSpacing: 0.5,
              ),
            ),

            // Actions on the right (Admin Dashboard & Notifications)
            Row(
              children: [
                if (isAdmin) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminDashboardScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFF0B4828),
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                GestureDetector(
                  onTap: () => _showNotificationsSheet(context),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('notifications').snapshots(),
                    builder: (context, snapshot) {
                      bool showBadge = false;
                      if (snapshot.hasData) {
                        final count = snapshot.data!.docs.where((doc) {
                          final target = doc.data() is Map && (doc.data() as Map).containsKey('target')
                              ? doc.get('target')
                              : 'all';
                          return target == 'all' || (userPhone != null && target == userPhone);
                        }).length;
                        showBadge = count > 0;
                      }

                      return Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.notifications_none,
                              color: Color(0xFF222222),
                              size: 20,
                            ),
                          ),
                          if (showBadge)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFD3B16A), // Premium Gold
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // --- Aaj Ka Swad Green Banner Card ---
  Widget _buildBannerCard() {
    return const BannerSlider();
  }

  // --- Order for Today Section ---
  Widget _buildOrderTodaySection(BuildContext context, MenuState menuState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Order for Today",
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            GestureDetector(
              onTap: () {
                if (menuState is MenuLoaded && menuState.lunchMenu != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TiffinDetailsScreen(
                        menu: menuState.lunchMenu!,
                        initialSlot: 'lunch',
                      ),
                    ),
                  );
                }
              },
              child: Row(
                children: [
                  Text(
                    "View Menu",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC3A575),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Color(0xFFC3A575),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Lunch Card
            Expanded(
              child: _buildMealSlotCard(
                context: context,
                menuState: menuState,
                isLunch: true,
                title: "Lunch",
                time: "11:30 AM - 1:30 PM",
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFE88A1A), // Saffron sun
              ),
            ),
            const SizedBox(width: 16),
            // Dinner Card
            Expanded(
              child: _buildMealSlotCard(
                context: context,
                menuState: menuState,
                isLunch: false,
                title: "Dinner",
                time: "7:00 PM - 9:00 PM",
                icon: Icons.nightlight_round_outlined,
                iconColor: const Color(0xFFC3A575), // Gold moon
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMealSlotCard({
    required BuildContext context,
    required MenuState menuState,
    required bool isLunch,
    required String title,
    required String time,
    required IconData icon,
    required Color iconColor,
  }) {
    final hasMenu = menuState is MenuLoaded &&
        (isLunch ? menuState.lunchMenu != null : menuState.dinnerMenu != null);
    
    final menu = menuState is MenuLoaded
        ? (isLunch ? menuState.lunchMenu : menuState.dinnerMenu)
        : null;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          // Circular Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Builder(
            builder: (context) {
              final countdownText = _getCutoffCountdown(isLunch);
              final isClosed = countdownText == "Closed for Today";
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isClosed 
                      ? AppTheme.errorColor.withOpacity(0.08) 
                      : AppTheme.primaryGreen.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    countdownText,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: isClosed ? AppTheme.errorColor : AppTheme.primaryGreen,
                    ),
                  ),
                ),
              );
            }
          ),
          const SizedBox(height: 12),
          
          // Order Now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (hasMenu && menu != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TiffinDetailsScreen(
                        menu: menu,
                        initialSlot: isLunch ? 'lunch' : 'dinner',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("No $title menu is currently active. Please retry."),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F3A20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                "Order Now",
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Your Subscription Section ---
  Widget _buildSubscriptionSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your Subscription",
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final isLoggedIn = authState is AuthAuthenticated;
            
            if (!isLoggedIn) {
              return _buildSubscriptionPromoCard(context);
            }

            return BlocBuilder<OrdersCubit, OrdersState>(
              builder: (context, ordersState) {
                if (ordersState is OrdersLoaded) {
                  final activeSubs = ordersState.activeOrders.where((o) => o.orderStatus != 'cancelled').toList();
                  if (activeSubs.isNotEmpty) {
                    final activeOrder = activeSubs.first;
                    final String freq = activeOrder.frequency[0].toUpperCase() + activeOrder.frequency.substring(1);
                    final String slotText = activeOrder.deliverySlot == 'both' ? 'Lunch & Dinner' : (activeOrder.deliverySlot == 'lunch' ? 'Lunch Only' : 'Dinner Only');
                  
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SubscriptionDetailsScreen(order: activeOrder),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
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
                      child: Row(
                        children: [
                          // Plan Icon matching design
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: Color(0xFF0F3A20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.calendar_today_outlined,
                              color: Color(0xFFC3A575),
                              size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        "$freq Plan",
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          "Active",
                                          style: TextStyle(
                                            color: Colors.green.shade700,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "$slotText • ${activeOrder.mealsCount} Days",
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textMuted,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Next Delivery: Today, ${activeOrder.deliverySlot == 'dinner' ? 'Dinner' : 'Lunch'}",
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xFFC3A575),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Icon(
                              Icons.chevron_right,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    );
                }
              }

              // Default Promo if logged in but no active orders
              return _buildSubscriptionPromoCard(context);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSubscriptionPromoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3A20).withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_outlined,
              color: Color(0xFFC3A575),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Subscribe & Save 15%",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Get home-cooked meals delivered daily. Pause or skip anytime.",
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Small flat gold chevron link
          GestureDetector(
            onTap: () {
              final menuState = context.read<MenuCubit>().state;
              if (menuState is MenuLoaded && menuState.lunchMenu != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingFlowScreen(
                      menu: menuState.lunchMenu!,
                      initialSlot: 'lunch',
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Menu is loading, please try in a moment!"),
                  ),
                );
              }
            },
            child: const Icon(
              Icons.chevron_right,
              color: Color(0xFFC3A575),
            ),
          ),
        ],
      ),
    );
  }

  // --- Promo Coupon Card ---
  Widget _buildPromoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F2EB), // Brassy cream background tint
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.card_giftcard,
            color: Color(0xFFC3A575),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Get flat 15% off • Use code: ATITHI15",
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6B583E), // Soft dark brown matching mockup theme
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: Color(0xFFC3A575),
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    final String? userPhone = authState is AuthAuthenticated ? authState.user.phone : null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return FutureBuilder<List<Map<String, dynamic>>>(
              future: FirebaseService.instance.collectionGet('notifications').then((list) {
                // Filter notifications
                final filtered = list.where((n) {
                  final target = n['target'] ?? 'all';
                  return target == 'all' || (userPhone != null && target == userPhone);
                }).toList();
                
                // Sort by createdAt descending
                filtered.sort((a, b) {
                  final aTime = DateTime.tryParse(a['createdAt'] ?? '') ?? DateTime.now();
                  final bTime = DateTime.tryParse(b['createdAt'] ?? '') ?? DateTime.now();
                  return bTime.compareTo(aTime);
                });
                return filtered;
              }),
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppTheme.borderLight,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Announcements & Alerts",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          const Icon(Icons.notifications_active, color: AppTheme.secondaryMarigold),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _buildNotificationsList(snapshot, scrollController),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildNotificationsList(
    AsyncSnapshot<List<Map<String, dynamic>>> snapshot,
    ScrollController scrollController,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    
    if (snapshot.hasError) {
      return Center(child: Text("Error: ${snapshot.error}"));
    }
    
    final notifications = snapshot.data ?? [];
    
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.06),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_off_outlined,
                size: 48,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "No Alerts Yet",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              "You will see special updates and tiffin delivery notifications here.",
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: scrollController,
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final item = notifications[index];
        final title = item['title'] ?? 'Alert';
        final message = item['message'] ?? '';
        
        final timeRaw = item['createdAt'] ?? '';
        String timeFormatted = '';
        try {
          final timeParsed = DateTime.parse(timeRaw);
          timeFormatted = DateFormat('dd MMM, hh:mm a').format(timeParsed);
        } catch (_) {}

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.campaign, color: AppTheme.primaryGreen),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark),
                  ),
                ),
                Text(
                  timeFormatted,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                message,
                style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BannerSlider extends StatefulWidget {
  const BannerSlider({Key? key}) : super(key: key);

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController.hasClients) {
        int nextPage = _currentPage == 0 ? 1 : 0;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 175, // Fits the cooking illustration nicely
      child: PageView(
        controller: _pageController,
        onPageChanged: (page) {
          setState(() {
            _currentPage = page;
          });
        },
        children: [
          _buildCard(
            backgroundImage: 'assets/img/homeCard_3.png',
            title: "Maa ke haath ka,\nswad har roz.",
            subtitle: "Pure ingredients. \nHomemade love.",
          ),
          _buildCard(
            backgroundImage: 'assets/img/homeCard-1.png',
            title: "Aaj ka swad,\nghar jaisa pyaar.",
            subtitle: "Freshly cooked. \nTimely delivered.",
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String backgroundImage,
    required String title,
    required String subtitle,
  }) {
    final bool isCard1 = backgroundImage.contains('homeCard-1');
    
    final Gradient? cardGradient = isCard1
        ? const LinearGradient(
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFF5EFE3),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final Color? cardBgColor = isCard1 ? null : const Color(0xFF0F3A20);
    final Color titleColor = isCard1 ? const Color(0xFF0F3A20) : Colors.white;
    final Color subtitleColor = isCard1 ? const Color(0xFF8C7144) : const Color(0xFFF3EAD8);
    final Color dotActiveColor = isCard1 ? const Color(0xFF0F3A20) : const Color(0xFFC3A575);
    final Color dotInactiveColor = isCard1 ? const Color(0xFF0F3A20).withOpacity(0.15) : Colors.white24;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isCard1 
                ? const Color(0xFF8C6E43).withOpacity(0.08) 
                : const Color(0xFF0F3A20).withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(backgroundImage),
          fit: BoxFit.cover,
          alignment: Alignment.centerRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: subtitleColor,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ],
          ),
          Row(
            children: List.generate(2, (index) {
              return Container(
                width: index == _currentPage ? 12 : 6,
                height: 6,
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: index == _currentPage ? dotActiveColor : dotInactiveColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
