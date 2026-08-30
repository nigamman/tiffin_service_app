import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Local cache to preserve UI during Bloc Loading state transitions
  UserProfile? _user;

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
}
