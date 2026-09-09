import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';
import '../../policies/presentation/policy_center_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color primaryGreen = Color(0xFF0F3A20);

  // Local cache to preserve UI during Bloc Loading state transitions
  UserProfile? _user;
  bool _phonePromptShown = false;

  @override
  void initState() {
    super.initState();
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
            const Icon(Icons.phone_android, color: primaryGreen),
            const SizedBox(width: 8),
            Text(
              "Add Phone Number",
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: primaryGreen, fontSize: 15),
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
                    borderSide: const BorderSide(color: primaryGreen, width: 2),
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
              backgroundColor: primaryGreen,
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        bool isDetecting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
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
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
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
                                      valueColor: AlwaysStoppedAnimation(primaryGreen),
                                    ),
                                  )
                                : const Icon(Icons.my_location, size: 16, color: primaryGreen),
                            label: Text(
                              isDetecting ? "Detecting..." : "Locate Me",
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: primaryGreen,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Name
                      TextFormField(
                        controller: nameController,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          labelText: "Full Name",
                          labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Name is required" : null,
                      ),
                      const SizedBox(height: 14),
                      
                      // House No
                      TextFormField(
                        controller: houseController,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          labelText: "House / Flat No.",
                          labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "House No is required" : null,
                      ),
                      const SizedBox(height: 14),
                      
                      // Area
                      TextFormField(
                        controller: areaController,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          labelText: "Area / Locality",
                          labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? "Area is required" : null,
                      ),
                      const SizedBox(height: 14),
                      
                      // Landmark
                      TextFormField(
                        controller: landmarkController,
                        style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textDark),
                        decoration: InputDecoration(
                          labelText: "Landmark",
                          labelStyle: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textMuted),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                          ),
                        ),
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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppTheme.textDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            _user = state.user;
            WidgetsBinding.instance.addPostFrameCallback((_) => _checkPhoneMissing());
          }
          
          if (_user == null) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }

          final user = _user!;
          final hasAddress = user.houseNo.isNotEmpty && user.area.isNotEmpty;
          final isLoading = state is AuthLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- User Profile Header Card ---
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 16,
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
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: primaryGreen,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryGreen.withOpacity(0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
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
                                        color: AppTheme.textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.phone_outlined,
                                          size: 13,
                                          color: AppTheme.textMuted,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          "+91 ${user.phone}",
                                          style: GoogleFonts.poppins(
                                            color: AppTheme.textMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: _showEditAddressSheet,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.edit_outlined, color: primaryGreen, size: 15),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Edit",
                                        style: GoogleFonts.poppins(
                                          color: primaryGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Divider(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 16),
                          
                          // Delivery Address Box
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FA),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: primaryGreen.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on_outlined,
                                    color: primaryGreen,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Delivery Address",
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12.5,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      hasAddress
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "${user.houseNo}, ${user.area}",
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.textDark,
                                                    fontSize: 12.5,
                                                    height: 1.3,
                                                  ),
                                                ),
                                                if (user.landmark.isNotEmpty) ...[
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    "Landmark: ${user.landmark}",
                                                    style: GoogleFonts.poppins(
                                                      color: AppTheme.textMuted,
                                                      fontSize: 11.5,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            )
                                          : Text(
                                              "No address configured yet. Tap edit to set location.",
                                              style: GoogleFonts.poppins(
                                                color: AppTheme.textMuted,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Help & Support Center List
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildTabItem(
                            icon: Icons.headset_mic_outlined,
                            title: "Customer Support & Contact Us",
                            subtitle: "Phone (+91 9119724875), Email & Office Address",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PolicyCenterScreen(initialSection: PolicySection.contactUs),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _buildTabItem(
                            icon: Icons.info_outline_rounded,
                            title: "About Atithi Bhoj",
                            subtitle: "Our business details & mission in Kanpur",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PolicyCenterScreen(initialSection: PolicySection.aboutUs),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _buildTabItem(
                            icon: Icons.sell_outlined,
                            title: "Pricing & Subscription Plans",
                            subtitle: "Transparent plan rates and meal pricing",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PolicyCenterScreen(initialSection: PolicySection.pricing),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _buildTabItem(
                            icon: Icons.replay_circle_filled_outlined,
                            title: "Cancellation & Refund Policy",
                            subtitle: "Subscription refunds and cancellation rules",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PolicyCenterScreen(initialSection: PolicySection.cancellationRefund),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _buildTabItem(
                            icon: Icons.local_shipping_outlined,
                            title: "Shipping & Delivery Policy",
                            subtitle: "5km delivery zone, timings, and rules",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PolicyCenterScreen(initialSection: PolicySection.shippingDelivery),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _buildTabItem(
                            icon: Icons.gavel_outlined,
                            title: "Terms, Conditions & Privacy",
                            subtitle: "Terms of service and data privacy commitment",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const PolicyCenterScreen(initialSection: PolicySection.terms),
                                ),
                              );
                            },
                          ),
                          Divider(height: 1, color: Colors.grey.shade100),
                          _buildTabItem(
                            icon: Icons.star_rate_rounded,
                            title: "Rate Us on Play Store ⭐",
                            subtitle: "Loved our food? Leave us a review on Google Play",
                            onTap: _openPlayStore,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Log Out Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          context.read<AuthCubit>().logout();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Logged out successfully")),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red.shade700,
                          side: BorderSide(color: Colors.red.shade200, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.red.shade50.withOpacity(0.4),
                          elevation: 0,
                        ),
                        icon: Icon(Icons.logout, size: 18, color: Colors.red.shade700),
                        label: Text(
                          "Log Out",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    
                    // Footer Info
                    Center(
                      child: Column(
                        children: [
                          Text(
                            "Atithi Bhoj Tiffin Service",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: primaryGreen,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "App Version 1.0  •  Made with ❤️ by nigamman",
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (isLoading)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.12),
                    child: const Center(
                      child: CircularProgressIndicator(color: primaryGreen),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openPlayStore() async {
    const packageName = 'com.nigamman.atithibhoj';
    final marketUri = Uri.parse('market://details?id=$packageName');
    final webUri = Uri.parse('https://play.google.com/store/apps/details?id=$packageName');

    try {
      if (await canLaunchUrl(marketUri)) {
        await launchUrl(marketUri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUri);
      }
    } catch (e) {
      debugPrint("Could not launch Play Store: $e");
    }
  }

  Widget _buildTabItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: primaryGreen.withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: primaryGreen, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppTheme.textDark),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(fontSize: 11.5, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
