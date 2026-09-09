import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:in_app_update/in_app_update.dart';
import 'firebase_service.dart';

class UpdateService {
  static const int currentVersionCode = 2; // Current build versionCode (+2 in pubspec.yaml)
  static const String currentVersionName = "1.0.0";
  static const String packageName = "com.nigamman.atithibhoj";

  static Future<void> checkForUpdates(BuildContext context) async {
    // 1. Try Native Android In-App Update first (Works when live in Production on Google Play Store)
    if (Platform.isAndroid) {
      try {
        final AppUpdateInfo info = await InAppUpdate.checkForUpdate();
        if (info.updateAvailability == UpdateAvailability.updateAvailable) {
          if (info.immediateUpdateAllowed) {
            await InAppUpdate.performImmediateUpdate();
            return;
          } else if (info.flexibleUpdateAllowed) {
            await InAppUpdate.startFlexibleUpdate();
            await InAppUpdate.completeFlexibleUpdate();
            return;
          }
        }
      } catch (e) {
        debugPrint("Native Play Store update check note: $e (Falling back to Firestore config)");
      }
    }

    // 2. Fallback to Instant Firestore Remote Config (Works in Closed Testing, Internal Testing & Production)
    try {
      final config = await FirebaseService.instance.docGet('app_config', 'version_info');
      
      if (config == null) return;

      final int latestVersionCode = (config['latestVersionCode'] as num?)?.toInt() ?? currentVersionCode;
      final int minRequiredVersionCode = (config['minRequiredVersionCode'] as num?)?.toInt() ?? 1;
      final bool forceUpdate = config['forceUpdate'] == true || currentVersionCode < minRequiredVersionCode;

      final String updateTitle = (config['updateTitle'] ?? "New Update Available 🚀").toString();
      final String updateMessage = (config['updateMessage'] ?? 
          "A new version of Atithi Bhoj is available on Google Play Store with performance improvements and bug fixes.").toString();

      if (latestVersionCode > currentVersionCode && context.mounted) {
        _showUpdateDialog(
          context,
          title: updateTitle,
          message: updateMessage,
          forceUpdate: forceUpdate,
        );
      }
    } catch (e) {
      debugPrint("Error checking for app updates: $e");
    }
  }

  static Future<void> _openPlayStore() async {
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

  static void _showUpdateDialog(
    BuildContext context, {
    required String title,
    required String message,
    required bool forceUpdate,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            backgroundColor: const Color(0xFFF9F7F2),
            contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B4828).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    color: Color(0xFF0B4828),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0B4828),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                // Update Now Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _openPlayStore();
                    },
                    icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                    label: Text(
                      "Update Now on Play Store",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B4828),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                if (!forceUpdate) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Later",
                      style: GoogleFonts.poppins(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
