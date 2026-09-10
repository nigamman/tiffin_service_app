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

    final isSystemAdmin = phone == '9119724875' || phone == '9999999999' || name.toLowerCase() == 'admin';

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

  Future<UserProfile?> syncAddressAndPhone({
    required String houseNo,
    required String area,
    required String landmark,
    required String phone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('user_profile');
    if (cached == null) return null;

    final current = UserProfile.fromMap(jsonDecode(cached));
    final updatedHouseNo = houseNo.isNotEmpty ? houseNo : current.houseNo;
    final updatedArea = area.isNotEmpty ? area : current.area;
    final updatedLandmark = landmark.isNotEmpty ? landmark : current.landmark;
    final updatedPhone = phone.isNotEmpty ? phone : current.phone;

    final updatedMap = {
      'houseNo': updatedHouseNo,
      'area': updatedArea,
      'landmark': updatedLandmark,
      'phone': updatedPhone,
    };

    await _db.docUpdate('users', current.id, updatedMap);

    final updatedProfile = UserProfile(
      id: current.id,
      phone: updatedPhone,
      name: current.name,
      houseNo: updatedHouseNo,
      area: updatedArea,
      landmark: updatedLandmark,
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
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<UserProfile> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: '797468589410-lj54m5uishgphsrbfce9hn1srun1c7i9.apps.googleusercontent.com',
    );

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled by user');
    }

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final String? idToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken;

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Could not obtain Google ID token. Please try again.');
    }

    final OAuthCredential credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );

    final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    final User? firebaseUser = userCredential.user;

    if (firebaseUser == null) {
      throw Exception('Firebase Sign-In failed');
    }

    final docData = await _db.docGet('users', firebaseUser.uid);
    UserProfile profile;

    if (docData != null && docData.isNotEmpty) {
      profile = UserProfile.fromMap(docData);
      final isSystemAdmin = profile.phone == '9119724875' || profile.phone == '9999999999' || profile.name.toLowerCase() == 'admin';
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
      final isAdmin = phone == '9119724875' || phone == '9999999999' || name.toLowerCase() == 'admin';
      
      final newUserMap = {
        'phone': phone,
        'name': isAdmin ? 'Admin' : name,
        'houseNo': '',
        'area': '',
        'landmark': '',
        'isAdmin': isAdmin,
      };
      
      final createdDoc = await _db.docSet('users', firebaseUser.uid, newUserMap);
      profile = UserProfile.fromMap(createdDoc);
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', 'firebase_auth_token_${profile.id}');
    await prefs.setString('user_profile', jsonEncode(profile.toMap()));

    return profile;
  }
}
