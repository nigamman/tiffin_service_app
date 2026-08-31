import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  // Local cache to preserve UI during Bloc Loading state transitions
  UserProfile? _user;

  @override
  void initState() {
    super.initState();
    context.read<OrdersCubit>().loadOrders();
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
      final house = "${place.subThoroughfare ?? ''} ${place.thoroughfare ?? ''}".trim();
      final area = "${place.subLocality ?? ''} ${place.locality ?? ''}".trim();
      final landmark = "${place.name ?? ''} ${place.postalCode ?? ''}".trim();

      houseController.text = house.isNotEmpty ? house : "Plot/House detected";
      areaController.text = area.isNotEmpty ? area : "Locality detected";
      landmarkController.text = landmark;
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
                    // Profile Card Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppTheme.primaryGreen.withOpacity(0.08),
                          child: Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : 'C',
                            style: const TextStyle(
                              color: AppTheme.primaryGreen,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "+91 ${user.phone}",
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Address Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Delivery Address",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                          icon: const Icon(Icons.edit, size: 16),
                          label: Text(hasAddress ? "Edit" : "Add"),
                          onPressed: _showEditAddressSheet,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: hasAddress
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.houseNo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${user.area}, Kanpur",
                                  style: const TextStyle(color: AppTheme.textDark),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Landmark: ${user.landmark}",
                                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                                ),
                              ],
                            )
                          : const Text(
                              "No address configured yet. Tap Edit/Add to set delivery location.",
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                            ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "Manage Subscriptions",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                    ),
                    const SizedBox(height: 12),
                    BlocBuilder<OrdersCubit, OrdersState>(
                      builder: (context, ordersState) {
                        if (ordersState is OrdersLoading) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
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
                                border: Border.all(color: AppTheme.borderLight),
                              ),
                              child: const Text(
                                "No active subscriptions. Subscribe to a plan to manage it here.",
                                style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
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
                    const SizedBox(height: 40),

                    // Log out
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
          border: Border.all(color: AppTheme.borderLight),
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
                    color: AppTheme.primaryGreen.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "${order.frequency.toUpperCase()} SUBSCRIPTION",
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
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
                color: AppTheme.textDark,
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
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.borderLight.withOpacity(0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const Divider(height: 32, color: AppTheme.borderLight),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isTargetSkipped 
                        ? AppTheme.errorColor.withOpacity(0.06)
                        : AppTheme.primaryGreen.withOpacity(0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isTargetSkipped ? Icons.block_outlined : Icons.delivery_dining_outlined,
                    size: 18,
                    color: isTargetSkipped ? AppTheme.errorColor : AppTheme.primaryGreen,
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
                          color: isTargetSkipped ? AppTheme.errorColor : AppTheme.textDark,
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
                    : AppTheme.secondaryMarigold,
                side: BorderSide(
                  color: (isTargetSkipped || (!isTargetSkipped && hasReachedSkipLimit)) 
                      ? AppTheme.borderLight 
                      : AppTheme.secondaryMarigold,
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
}
