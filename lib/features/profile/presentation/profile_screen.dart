import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/presentation/auth_cubit.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Toggle status state
  bool _useMockMode = ApiConstants.useMockApi;

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
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Edit Profile Details",
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
          if (state is! AuthAuthenticated) {
            return const SizedBox();
          }

          final user = state.user;
          final hasAddress = user.houseNo.isNotEmpty && user.area.isNotEmpty;

          return SingleChildScrollView(
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
                          fontFamily: 'Outfit',
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
                const SizedBox(height: 32),

                // App settings / Developer Options
                Text(
                  "Developer Console",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.secondaryMarigold,
                      ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderLight),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Emulated Firestore Mode",
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark, fontSize: 14),
                          ),
                          Text(
                            "Uses emulated Cloud Firestore collections",
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                      Switch(
                        value: _useMockMode,
                        activeColor: AppTheme.primaryGreen,
                        onChanged: (val) {
                          if (val == false) {
                            // Inform user that actual Firebase linking is required
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("To use live database, install Firebase packages and run 'flutterfire configure'."),
                                duration: Duration(seconds: 4),
                              ),
                            );
                            setState(() {
                              _useMockMode = true; // Force it back to true since packages aren't imported yet
                            });
                          } else {
                            setState(() {
                              _useMockMode = true;
                              ApiConstants.useMockApi = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

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
          );
        },
      ),
    );
  }
}
