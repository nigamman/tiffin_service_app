import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/data/auth_repository.dart';
import '../../orders/presentation/orders_cubit.dart';
import '../../orders/data/orders_repository.dart';
import '../../orders/presentation/subscription_details_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/notification_overlay.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color curryGreen = Color(0xFF0F3A20);
  static const Color turmericGold = Color(0xFFC3A575);

  // Local cache to preserve UI during Bloc Loading state transitions
  UserProfile? _user;
  int _activeTab = 0; // 0 = Subscriptions, 1 = Help & Info
  bool _phonePromptShown = false;

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().loadOrders();
    // Check after first frame if phone is missing (Google login)
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPhoneMissing());
  }

  void _checkPhoneMissing() {
    if (_phonePromptShown) return;
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated && authState.user.phone.isEmpty) {
      _phonePromptShown = true;
      _showPhoneDialog();
    }
  }

  void _showPhoneDialog() {
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.phone_android, color: curryGreen),
            const SizedBox(width: 8),
            Text(
              "Add Phone Number",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: curryGreen, fontSize: 15),
            ),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Since you signed in with Google, please enter your phone number so we can contact you about your deliveries.",
                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textMuted, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: InputDecoration(
                  labelText: "Phone Number",
                  prefixText: "+91 ",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: curryGreen, width: 2),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Phone number is required";
                  if (v.length != 10) return "Enter a valid 10-digit number";
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Skip", style: GoogleFonts.poppins(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: curryGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                context.read<AuthCubit>().updatePhone(phoneController.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _detectLocation(
    TextEditingController houseController,
    TextEditingController areaController,
    TextEditingController landmarkController,
  ) async {
    // 1. Check services
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled. Please enable GPS.");
    }

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission was denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied. Please enable them in app settings.");
    }

    // 3. Get coordinates
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4. Reverse geocode
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      Placemark place = placemarks.first;
      
      // Parse details
      String detectedHouseNo = "";
      String detectedArea = "";

      // 1. House / Flat No.
      if (place.name != null && 
          place.name!.isNotEmpty && 
          place.name != place.subLocality && 
          place.name != place.locality) {
        detectedHouseNo = place.name!;
      } else if (place.subThoroughfare != null && place.subThoroughfare!.isNotEmpty) {
        detectedHouseNo = place.subThoroughfare!;
      }

      // 2. Area / Locality
      final List<String> addressParts = [];
      if (place.thoroughfare != null && 
          place.thoroughfare!.isNotEmpty && 
          place.thoroughfare != place.name) {
        addressParts.add(place.thoroughfare!);
      }
      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }
      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }
      detectedArea = addressParts.isEmpty ? "Locality detected" : addressParts.join(", ");

      houseController.text = detectedHouseNo.isNotEmpty ? detectedHouseNo : "Plot/House detected";
      areaController.text = detectedArea;
      landmarkController.text = ""; // Keep empty by default so user can fill in a real landmark
    } else {
      throw Exception("No address details found for your coordinates.");
    }
  }

  void _showEditAddressSheet() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final user = authState.user;
    final nameController = TextEditingController(text: user.name);
    final houseController = TextEditingController(text: user.houseNo);
    final areaController = TextEditingController(text: user.area);
    final landmarkController = TextEditingController(text: user.landmark);

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        bool isDetecting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Edit Profile Details",
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        TextButton.icon(
                          onPressed: isDetecting
                              ? null
                              : () async {
                                  setModalState(() => isDetecting = true);
                                  try {
                                    await _detectLocation(
                                      houseController,
                                      areaController,
                                      landmarkController,
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Could not retrieve location: $e"),
                                        backgroundColor: AppTheme.errorColor,
                                      ),
                                    );
                                  } finally {
                                    setModalState(() => isDetecting = false);
                                  }
                                },
                          icon: isDetecting
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryGreen),
                                  ),
                                )
                              : const Icon(Icons.my_location, size: 16),
                          label: Text(
                            isDetecting ? "Detecting..." : "Locate Me",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                
                // Name
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Full Name"),
                  validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null,
                ),
                const SizedBox(height: 12),
                
                // House No
                TextFormField(
                  controller: houseController,
                  decoration: const InputDecoration(labelText: "House / Flat No."),
                  validator: (v) => (v == null || v.isEmpty) ? "House No is required" : null,
                ),
                const SizedBox(height: 12),
                
                // Area
                TextFormField(
                  controller: areaController,
                  decoration: const InputDecoration(labelText: "Area / Locality"),
                  validator: (v) => (v == null || v.isEmpty) ? "Area is required" : null,
                ),
                const SizedBox(height: 12),
                
                // Landmark
                TextFormField(
                  controller: landmarkController,
                  decoration: const InputDecoration(labelText: "Landmark"),
                  validator: (v) => (v == null || v.isEmpty) ? "Landmark is required" : null,
                ),
                const SizedBox(height: 24),

                CustomButton(
                  text: "Save Details",
                  onPressed: () {
                    if (formKey.currentState?.validate() ?? false) {
                      this.context.read<AuthCubit>().updateProfile(
                            nameController.text.trim(),
                            houseController.text.trim(),
                            areaController.text.trim(),
                            landmarkController.text.trim(),
                          );
                      Navigator.pop(context);
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        const SnackBar(content: Text("Profile details saved successfully")),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text("My Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            _user = state.user;
            // Trigger phone prompt if it slipped through initState (e.g. state arrives late)
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkPhoneMissing());
          }
          
          if (_user == null) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final user = _user!;
          final hasAddress = user.houseNo.isNotEmpty && user.area.isNotEmpty;
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: turmericGold, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.015),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: curryGreen,
                                child: CircleAvatar(
                                  radius: 30.5,
                                  backgroundColor: Colors.white,
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                                    style: const TextStyle(
                                      color: curryGreen,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: curryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "+91 ${user.phone}",
                                      style: GoogleFonts.poppins(
                                        color: AppTheme.textMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: curryGreen, size: 20),
                                onPressed: _showEditAddressSheet,
                                style: IconButton.styleFrom(
                                  backgroundColor: turmericGold.withOpacity(0.12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24, color: turmericGold, thickness: 0.8),
                          Text(
                            "Delivery Address",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: curryGreen,
                            ),
                          ),
                          const SizedBox(height: 6),
                          hasAddress
                              ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.houseNo,
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppTheme.textDark, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.area,
                                      style: GoogleFonts.poppins(color: AppTheme.textDark, fontSize: 13),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Landmark: ${user.landmark}",
                                      style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                                    ),
                                  ],
                                )
                              : Text(
                                  "No address configured yet. Tap edit to set location.",
                                  style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                                ),

                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECE7DB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeTab = 0;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _activeTab == 0 ? curryGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _activeTab == 0
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Subscriptions",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _activeTab == 0 ? turmericGold : curryGreen.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _activeTab = 1;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: _activeTab == 1 ? curryGreen : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: _activeTab == 1
                                      ? [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.05),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : [],
                                ),
                                child: Center(
                                  child: Text(
                                    "Help & Info",
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: _activeTab == 1 ? turmericGold : curryGreen.withOpacity(0.6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _activeTab == 0
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Active Subscriptions",
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: curryGreen,
                                ),
                              ),
                              const SizedBox(height: 10),
                              BlocBuilder<OrdersCubit, OrdersState>(
                                builder: (context, ordersState) {
                                  if (ordersState is OrdersLoading) {
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: 20),
                                        child: CircularProgressIndicator(color: curryGreen),
                                      ),
                                    );
                                  }
                                  if (ordersState is OrdersLoaded) {
                                    final activeSubs = ordersState.activeOrders
                                        .where((o) => o.frequency != 'one-time')
                                        .toList();

                                    if (activeSubs.isEmpty) {
                                      return Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: turmericGold, width: 1.2),
                                        ),
                                        child: Text(
                                          "No active subscriptions. Subscribe to a plan to manage it here.",
                                          style: GoogleFonts.poppins(color: AppTheme.textMuted, fontSize: 12),
                                        ),
                                      );
                                    }

                                    return ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: activeSubs.length,
                                      itemBuilder: (context, index) {
                                        final order = activeSubs[index];
                                        return _buildSubscriptionManagementCard(context, order);
                                      },
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ],
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: turmericGold, width: 1.5),
                            ),
                            child: Column(
                              children: [
                                _buildTabItem(
                                  icon: Icons.phone_in_talk,
                                  title: "Customer Care",
                                  subtitle: "Call support (+91 9450900700)",
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Calling Customer Care (+91 9450900700)...")),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE2D6C1)),
                                _buildTabItem(
                                  icon: Icons.bug_report,
                                  title: "Report a Bug",
                                  subtitle: "Send a bug report to developer",
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Redirecting to bug report screen...")),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE2D6C1)),
                                _buildTabItem(
                                  icon: Icons.star_rate,
                                  title: "Rate Our App",
                                  subtitle: "Rate us on Play Store",
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Redirecting to Play Store...")),
                                    );
                                  },
                                ),
                                const Divider(height: 1, color: Color(0xFFE2D6C1)),
                                _buildTabItem(
                                  icon: Icons.share,
                                  title: "Share App",
                                  subtitle: "Invite friends and family",
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Opening share panel...")),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: "Log Out",
                      isSecondary: true,
                      icon: Icons.logout,
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Logged out successfully")),
                        );
                      },
                    ),
                    const SizedBox(height: 32),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Atithi Bhoj Tiffin Service",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: curryGreen,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "App Version: 1.0",
                                style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                "Developer: nigamman",
                                style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.12),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSubscriptionManagementCard(BuildContext context, OrderModel order) {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final startNormalized = DateTime(order.startDate.year, order.startDate.month, order.startDate.day);

    final totalMeals = order.totalMeals;
    final remainingMeals = order.remainingMeals;
    final double progressPercent = order.progressPercent;

    // Determine cutoff time (2 hours before delivery slot)
    int cutoffHour = 9; // 9:30 AM
    int cutoffMinute = 30;
    String cutoffText = "9:30 AM";
    if (order.deliverySlot == 'dinner') {
      cutoffHour = 17; // 5:00 PM
      cutoffMinute = 0;
      cutoffText = "5:00 PM";
    } else if (order.deliverySlot == 'both') {
      cutoffHour = 9; // 9:30 AM for lunch
      cutoffMinute = 30;
      cutoffText = "9:30 AM";
    }

    final todayCutoff = DateTime(now.year, now.month, now.day, cutoffHour, cutoffMinute);

    DateTime targetSkipDate;
    if (startNormalized.isAfter(todayNormalized)) {
      targetSkipDate = startNormalized;
    } else if (now.isBefore(todayCutoff)) {
      targetSkipDate = todayNormalized;
    } else {
      targetSkipDate = todayNormalized.add(const Duration(days: 1));
    }

    final isTargetSkipped = order.skippedDates.any(
      (d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(targetSkipDate),
    );

    final isTargetToday = DateTime(targetSkipDate.year, targetSkipDate.month, targetSkipDate.day)
        .isAtSameMomentAs(todayNormalized);
    final isTargetTomorrow = DateTime(targetSkipDate.year, targetSkipDate.month, targetSkipDate.day)
        .isAtSameMomentAs(todayNormalized.add(const Duration(days: 1)));

    final String dayLabel = isTargetToday 
        ? "Today" 
        : (isTargetTomorrow ? "Tomorrow" : DateFormat('EEEE, dd MMM').format(targetSkipDate));

    final String slotTimingText;
    if (order.deliverySlot == 'lunch') {
      slotTimingText = "11:30 AM - 1:30 PM";
    } else if (order.deliverySlot == 'dinner') {
      slotTimingText = "7:00 PM - 9:00 PM";
    } else {
      slotTimingText = "Lunch: 11:30 AM - 1:30 PM & Dinner: 7:00 PM - 9:00 PM";
    }

    // Count skipped slots in these 7 days
    int skipCount = 0;
    final List<DateTime> next7Days = List.generate(7, (i) => todayNormalized.add(Duration(days: i)));
    for (final day in next7Days) {
      final isDaySkipped = order.skippedDates.any((d) => DateTime(d.year, d.month, d.day).isAtSameMomentAs(day));
      if (isDaySkipped) {
        skipCount++;
        continue;
      }
      for (final slot in ['lunch', 'dinner']) {
        final slotKey = "${DateFormat('yyyy-MM-dd').format(day)}_$slot";
        if (order.skippedSlots.contains(slotKey)) {
          skipCount++;
        }
      }
    }
    final bool hasReachedSkipLimit = skipCount >= 1;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionDetailsScreen(order: order),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: turmericGold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: curryGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${order.frequency.toUpperCase()} SUBSCRIPTION",
                    style: const TextStyle(
                      color: curryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppTheme.successColor, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "Active",
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Home Tiffin Meal  •  ${order.quantity} Box (${order.deliverySlot.toUpperCase()})",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: curryGreen,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subscription Progress",
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                Text(
                  "$remainingMeals of $totalMeals meals left",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: curryGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: turmericGold.withOpacity(0.15),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: curryGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const Divider(height: 32, color: Color(0xFFE2D6C1)),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTargetSkipped 
                        ? AppTheme.errorColor.withOpacity(0.06)
                        : curryGreen.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTargetSkipped ? Icons.block_outlined : Icons.delivery_dining_outlined,
                    size: 18,
                    color: isTargetSkipped ? AppTheme.errorColor : curryGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTargetSkipped
                            ? "$dayLabel's Delivery Skipped"
                            : "Scheduled $dayLabel",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isTargetSkipped ? AppTheme.errorColor : curryGreen,
                        ),
                      ),
                      Text(
                        isTargetSkipped
                            ? "You will not receive tiffin box for $dayLabel's ${order.deliverySlot} slot."
                            : "Delivered $dayLabel during ${order.deliverySlot.toUpperCase()} slot ($slotTimingText).",
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: (isTargetSkipped || (!isTargetSkipped && hasReachedSkipLimit)) 
                    ? AppTheme.textMuted 
                    : turmericGold,
                side: BorderSide(
                  color: (isTargetSkipped || (!isTargetSkipped && hasReachedSkipLimit)) 
                      ? AppTheme.borderLight 
                      : turmericGold,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                minimumSize: const Size(double.infinity, 44),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              icon: Icon(
                isTargetSkipped 
                    ? Icons.check_circle_outline 
                    : (hasReachedSkipLimit ? Icons.lock_outline : Icons.skip_next_outlined),
                size: 16,
              ),
              label: Text(
                isTargetSkipped 
                    ? "Delivery Skipped" 
                    : (hasReachedSkipLimit ? "Weekly Skip Limit Reached" : "Skip $dayLabel's Delivery"),
              ),
              onPressed: (isTargetSkipped || hasReachedSkipLimit)
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (BuildContext dialogContext) {
                          return AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            title: const Text("Confirm Skip"),
                            content: Text("Are you sure you want to skip $dayLabel's delivery? Note: This action cannot be undone and you cannot unskip this delivery later."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted)),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  context.read<OrdersCubit>().skipDeliveryDate(order.id, targetSkipDate);
                                  NotificationOverlay.show(
                                    context,
                                    title: "Delivery Skipped",
                                    message: "Your delivery has been skipped for $dayLabel.",
                                    icon: Icons.skip_next,
                                  );
                                },
                                child: const Text("Skip", style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          );
                        },
                      );
                    },
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                "Note: Skip requests accepted up to 2 hours before delivery ($cutoffText cutoff)",
                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: curryGreen.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: curryGreen, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: turmericGold, size: 18),
      onTap: onTap,
    );
  }
}
