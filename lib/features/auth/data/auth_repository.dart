import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/firebase_service.dart';

class UserProfile {
  final String id;
  final String phone;
  final String name;
  final String houseNo;
  final String area;
  final String landmark;
  final bool isAdmin;

  UserProfile({
    required this.id,
    required this.phone,
    required this.name,
    this.houseNo = '',
    this.area = '',
    this.landmark = '',
    required this.isAdmin,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'houseNo': houseNo,
      'area': area,
      'landmark': landmark,
      'isAdmin': isAdmin,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      houseNo: map['houseNo'] ?? '',
      area: map['area'] ?? '',
      landmark: map['landmark'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}

class AuthRepository {
  final FirebaseService _db = FirebaseService.instance;

  Future<UserProfile> verifyOtp(String phone, String otp) async {
    // 1. Mock verify SMS code (standard code 123456)
    if (otp != '123456') {
      throw Exception('Invalid OTP verification code');
    }

    // 2. Fetch user document from Firestore `/users` collection
    final existingUsers = await _db.collectionGetWhere('users', 'phone', phone);
    UserProfile profile;

    if (existingUsers.isNotEmpty) {
      profile = UserProfile.fromMap(existingUsers.first);
    } else {
      // 3. Create a new Firestore user document on signup
      final isAdmin = phone.endsWith('9999') || phone == '9876543210';
      final newUserMap = {
        'phone': phone,
        'name': 'Customer ${phone.substring(phone.length - 4)}',
        'houseNo': '',
        'area': '',
        'landmark': '',
        'isAdmin': isAdmin,
      };

      final createdDoc = await _db.docAdd('users', newUserMap);
      profile = UserProfile.fromMap(createdDoc);
    }

    // Associate past orders with this newly created user ID
    _db.associateUserOrders(phone, profile.id);

    // 4. Cache JWT mock token and profile in shared_preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'mock_firebase_auth_token_${profile.id}');
    await prefs.setString('user_profile', jsonEncode(profile.toMap()));

    return profile;
  }

  Future<UserProfile?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_profile');
    if (cached != null) {
      return UserProfile.fromMap(jsonDecode(cached));
    }
    return null;
  }

  Future<UserProfile> updateProfile(String name, String houseNo, String area, String landmark) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_profile');
    if (cached == null) {
      throw Exception('No authenticated user found');
    }

    final current = UserProfile.fromMap(jsonDecode(cached));
    final updatedMap = {
      'name': name,
      'houseNo': houseNo,
      'area': area,
      'landmark': landmark,
    };

    // 1. Update document in Firestore
    await _db.docUpdate('users', current.id, updatedMap);

    // 2. Refresh local Cache
    final updatedProfile = UserProfile(
      id: current.id,
      phone: current.phone,
      name: name,
      houseNo: houseNo,
      area: area,
      landmark: landmark,
      isAdmin: current.isAdmin,
    );

    await prefs.setString('user_profile', jsonEncode(updatedProfile.toMap()));
    return updatedProfile;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
  }
}
