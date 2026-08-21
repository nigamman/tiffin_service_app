import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api'; // Android Emulator loopback to host
      }
    } catch (_) {}
    return 'http://localhost:5000/api'; // iOS Simulator or Web fallback
  }

  // Developer Toggle: Set to true to run the app entirely offline with simulated delay.
  // Set to false to connect to the Node.js Express server.
  static bool useMockApi = true;
}
