import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

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
    final addr = map['address'] as Map<String, dynamic>? ?? {};
    return UserProfile(
      id: map['id'] ?? map['_id'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      houseNo: addr['houseNo'] ?? map['houseNo'] ?? '',
      area: addr['area'] ?? map['area'] ?? '',
      landmark: addr['landmark'] ?? map['landmark'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
    );
  }
}

class AuthRepository {
  final ApiClient _apiClient = ApiClient();

  Future<UserProfile> verifyOtp(String phone, String otp) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate api call delay
      
      final mockUser = UserProfile(
        id: 'mock_usr_${phone.substring(phone.length - 4)}',
        phone: phone,
        name: 'Customer ${phone.substring(phone.length - 4)}',
        isAdmin: phone.endsWith('9999') || phone == '9876543210',
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', 'mock_phone_$phone');
      await prefs.setString('user_profile', jsonEncode(mockUser.toMap()));
      
      return mockUser;
    } else {
      final response = await _apiClient.post('/auth/verify-otp', {
        'phone': phone,
        'otp': otp,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final userProfile = UserProfile.fromMap(data['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        await prefs.setString('user_profile', jsonEncode(userProfile.toMap()));

        return userProfile;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify OTP');
      }
    }
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
    UserProfile current;
    
    if (cached != null) {
      current = UserProfile.fromMap(jsonDecode(cached));
    } else {
      throw Exception('No user is currently logged in');
    }

    final updated = UserProfile(
      id: current.id,
      phone: current.phone,
      name: name,
      houseNo: houseNo,
      area: area,
      landmark: landmark,
      isAdmin: current.isAdmin,
    );

    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 600));
      await prefs.setString('user_profile', jsonEncode(updated.toMap()));
      return updated;
    } else {
      final response = await _apiClient.put('/auth/profile', {
        'name': name,
        'address': {
          'houseNo': houseNo,
          'area': area,
          'landmark': landmark,
        }
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userProfile = UserProfile.fromMap(data['user']);
        await prefs.setString('user_profile', jsonEncode(userProfile.toMap()));
        return userProfile;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to update profile');
      }
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
  }
}
