import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  // Private Constructor
  FirebaseService._internal();

  // Singleton Instance
  static final FirebaseService instance = FirebaseService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Seeding check method
  Future<void> seedIfEmpty() async {
    try {
      final menuSnap = await _firestore.collection('menu').limit(1).get();
      if (menuSnap.docs.isEmpty) {
        // Seed Active Lunch Menu
        await _firestore.collection('menu').doc('mock_menu_today_101').set({
          'id': 'mock_menu_today_101',
          'items': ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'],
          'price': 80.0,
          'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
          'isActive': true,
          'slot': 'lunch',
          'date': DateTime.now().toIso8601String(),
        });

        // Seed Active Dinner Menu
        await _firestore.collection('menu').doc('mock_menu_dinner_101').set({
          'id': 'mock_menu_dinner_101',
          'items': ['Paneer Butter Masala', 'Veg Jhalfrezi', '4 Roti', 'Steamed Rice', 'Salad', 'Rayta'],
          'price': 90.0,
          'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
          'isActive': true,
          'slot': 'dinner',
          'date': DateTime.now().toIso8601String(),
        });
      }

      final couponSnap = await _firestore.collection('coupons').limit(1).get();
      if (couponSnap.docs.isEmpty) {
        final couponsList = [
          {
            'id': 'coupon_first',
            'code': 'FIRSTTIFFIN',
            'discountType': 'fixed',
            'discountValue': 30.0,
            'minOrderValue': 80.0,
            'active': true,
            'usageCount': 0,
          },
          {
            'id': 'coupon_kanpur',
            'code': 'KANPUR50',
            'discountType': 'fixed',
            'discountValue': 50.0,
            'minOrderValue': 200.0,
            'active': true,
            'usageCount': 0,
          },
          {
            'id': 'coupon_welcome',
            'code': 'WELCOME20',
            'discountType': 'percent',
            'discountValue': 20.0,
            'maxDiscount': 100.0,
            'minOrderValue': 80.0,
            'active': true,
            'usageCount': 0,
          },
          {
            'id': 'coupon_weekly',
            'code': 'WEEKLY50',
            'discountType': 'fixed',
            'discountValue': 50.0,
            'minOrderValue': 500.0,
            'active': true,
            'usageCount': 0,
          }
        ];
        for (final c in couponsList) {
          await _firestore.collection('coupons').doc(c['id'] as String).set(c);
        }
      }
    } catch (e) {
      // Print seeding error but do not crash the app
      print("Seeding error: $e");
    }
  }

  // --- Firestore Real API ---

  Future<List<Map<String, dynamic>>> collectionGet(String collectionName) async {
    final querySnap = await _firestore.collection(collectionName).get();
    return querySnap.docs.map((doc) => doc.data()).toList();
  }

  Future<List<Map<String, dynamic>>> collectionGetWhere(
    String collectionName,
    String field,
    dynamic value,
  ) async {
    final querySnap = await _firestore
        .collection(collectionName)
        .where(field, isEqualTo: value)
        .get();
    return querySnap.docs.map((doc) => doc.data()).toList();
  }

  Future<Map<String, dynamic>?> docGet(String collectionName, String docId) async {
    final docSnap = await _firestore.collection(collectionName).doc(docId).get();
    return docSnap.data();
  }

  Future<Map<String, dynamic>> docAdd(String collectionName, Map<String, dynamic> data) async {
    final docRef = await _firestore.collection(collectionName).add(data);
    final updatedData = {
      ...data,
      'id': docRef.id,
    };
    await docRef.update({'id': docRef.id});
    return updatedData;
  }

  Future<Map<String, dynamic>> docSet(
    String collectionName,
    String docId,
    Map<String, dynamic> data,
  ) async {
    final docRef = _firestore.collection(collectionName).doc(docId);
    final docMap = {
      'id': docId,
      ...data,
    };
    await docRef.set(docMap);
    return docMap;
  }

  Future<void> docUpdate(
    String collectionName,
    String docId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection(collectionName).doc(docId).update(updates);
  }

  // Helper to match active orders with logged in users (optional on real firebase, but kept for simulation compatibility)
  Future<void> associateUserOrders(String phone, String userId) async {
    try {
      final ordersSnap = await _firestore
          .collection('orders')
          .where('contactPhone', isEqualTo: phone)
          .get();
          
      for (final doc in ordersSnap.docs) {
        await doc.reference.update({'user': userId});
      }
    } catch (e) {
      print("Error associating orders: $e");
    }
  }
}
