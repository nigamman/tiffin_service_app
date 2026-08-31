import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
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

  Future<UserProfile> getUserOrCreateProfile({
    required String id,
    required String phone,
    required String name,
  }) async {
    final existingUsers = await _db.collectionGetWhere('users', 'phone', phone);
    UserProfile profile;

    final isSystemAdmin = phone == '9450900700' || phone == '9999999999' || name.toLowerCase() == 'admin';

    if (existingUsers.isNotEmpty) {
      profile = UserProfile.fromMap(existingUsers.first);
      if (profile.name.isEmpty || profile.name.startsWith('Customer') || isSystemAdmin) {
        final updatedName = isSystemAdmin ? 'Admin' : name;
        await _db.docUpdate('users', profile.id, {
          'name': updatedName,
          'isAdmin': isSystemAdmin ? true : profile.isAdmin,
        });
        profile = UserProfile(
          id: profile.id,
          phone: profile.phone,
          name: updatedName,
          houseNo: profile.houseNo,
          area: profile.area,
          landmark: profile.landmark,
          isAdmin: isSystemAdmin ? true : profile.isAdmin,
        );
      }
    } else {
      final isAdmin = isSystemAdmin || phone.endsWith('9999') || phone == '9876543210';
      final newUserMap = {
        'phone': phone,
        'name': isAdmin ? 'Admin' : name,
        'houseNo': '',
        'area': '',
        'landmark': '',
        'isAdmin': isAdmin,
      };

      final createdDoc = await _db.docSet('users', id, newUserMap);
      profile = UserProfile.fromMap(createdDoc);
    }

    _db.associateUserOrders(phone, profile.id);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'firebase_auth_token_${profile.id}');
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

  Future<UserProfile> updatePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_profile');
    if (cached == null) {
      throw Exception('No authenticated user found');
    }

    final current = UserProfile.fromMap(jsonDecode(cached));

    // 1. Update Firestore
    await _db.docUpdate('users', current.id, {'phone': phone});

    // 2. Refresh local cache
    final updatedProfile = UserProfile(
      id: current.id,
      phone: phone,
      name: current.name,
      houseNo: current.houseNo,
      area: current.area,
      landmark: current.landmark,
      isAdmin: current.isAdmin,
    );

    await prefs.setString('user_profile', jsonEncode(updatedProfile.toMap()));
    return updatedProfile;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_profile');
    try {
      await GoogleSignIn().signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<UserProfile> signInWithGoogle() async {
    // 1. Trigger the Google Authentication flow
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    // 2. Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    // 3. Create a new credential
    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 4. Sign in to Firebase with the credential
    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Firebase Sign-In failed');
    }

    // 5. Look up or create user profile in Firestore
    final existingUsers = await _db.collectionGetWhere('users', 'id', firebaseUser.uid);
    UserProfile profile;

    if (existingUsers.isNotEmpty) {
      profile = UserProfile.fromMap(existingUsers.first);
      final isSystemAdmin = profile.phone == '9450900700' || profile.phone == '9999999999' || profile.name.toLowerCase() == 'admin';
      if (isSystemAdmin && !profile.isAdmin) {
        await _db.docUpdate('users', profile.id, {'isAdmin': true});
        profile = UserProfile(
          id: profile.id,
          phone: profile.phone,
          name: profile.name,
          houseNo: profile.houseNo,
          area: profile.area,
          landmark: profile.landmark,
          isAdmin: true,
        );
      }
    } else {
      final phone = firebaseUser.phoneNumber ?? '';
      final name = firebaseUser.displayName ?? 'Customer';
      final isAdmin = phone == '9450900700' || phone == '9999999999' || name.toLowerCase() == 'admin';
      
      final newUserMap = {
        'phone': phone,
        'name': isAdmin ? 'Admin' : name,
        'houseNo': '',
        'area': '',
        'landmark': '',
        'isAdmin': isAdmin,
      };
      
      // Set doc with Firebase User ID
      final createdDoc = await _db.docSet('users', firebaseUser.uid, newUserMap);
      profile = UserProfile.fromMap(createdDoc);
    }

    // Cache local profile
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'firebase_auth_token_${profile.id}');
    await prefs.setString('user_profile', jsonEncode(profile.toMap()));

    return profile;
  }
}
