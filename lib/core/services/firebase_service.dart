import 'dart:math';

class FirebaseService {
  // Private Constructor
  FirebaseService._internal() {
    _seedCollections();
  }

  // Singleton Instance
  static final FirebaseService instance = FirebaseService._internal();

  // Simulated Collections database
  final Map<String, Map<String, Map<String, dynamic>>> _db = {
    'users': {},
    'menu': {},
    'orders': {},
    'coupons': {},
    'payments': {},
  };

  void _seedCollections() {
    // 1. Seed Active Menu
    _db['menu']?['mock_menu_today_101'] = {
      'id': 'mock_menu_today_101',
      'items': ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'],
      'price': 80.0,
      'imageUrl': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      'isActive': true,
      'date': DateTime.now().toIso8601String(),
    };

    // 2. Seed Default Coupons
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
      _db['coupons']?[c['id'] as String] = c;
    }

    // 3. Seed some default user orders for order history mock
    _db['orders']?['mock_ord_901'] = {
      'id': 'mock_ord_901',
      'user': 'mock_usr_temp', // Will associate with user on login
      'frequency': 'weekly',
      'quantity': 1,
      'startDate': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
      'deliverySlot': 'lunch',
      'contactPhone': '9876543210',
      'pricePerMeal': 80.0,
      'mealsCount': 7,
      'totalAmount': 560.0,
      'discountAmount': 50.0,
      'finalAmount': 510.0,
      'paymentStatus': 'paid',
      'orderStatus': 'confirmed',
      'skippedDates': <String>[],
      'createdAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    };
  }

  // --- Firestore Simulation API ---

  Future<List<Map<String, dynamic>>> collectionGet(String collectionName) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final collection = _db[collectionName];
    if (collection == null) return [];
    return collection.values.toList();
  }

  Future<List<Map<String, dynamic>>> collectionGetWhere(
    String collectionName,
    String field,
    dynamic value,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final collection = _db[collectionName];
    if (collection == null) return [];
    
    return collection.values.where((doc) {
      return doc[field] == value;
    }).toList();
  }

  Future<Map<String, dynamic>?> docGet(String collectionName, String docId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return _db[collectionName]?[docId];
  }

  Future<Map<String, dynamic>> docAdd(String collectionName, Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final randomId = '${collectionName.substring(0, 3)}_${_generateRandomId()}';
    
    final Map<String, dynamic> newDoc = {
      'id': randomId,
      ...data,
    };
    
    _db[collectionName]?[randomId] = newDoc;
    return newDoc;
  }

  Future<Map<String, dynamic>> docSet(
    String collectionName,
    String docId,
    Map<String, dynamic> data,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final Map<String, dynamic> doc = {
      'id': docId,
      ...data,
    };
    _db[collectionName]?[docId] = doc;
    return doc;
  }

  Future<void> docUpdate(
    String collectionName,
    String docId,
    Map<String, dynamic> updates,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final doc = _db[collectionName]?[docId];
    if (doc != null) {
      _db[collectionName]?[docId] = {
        ...doc,
        ...updates,
      };
    } else {
      throw Exception('Document not found in $collectionName: $docId');
    }
  }

  // Helper to match active orders with logged in users
  void associateUserOrders(String phone, String userId) {
    final orders = _db['orders'];
    if (orders != null) {
      for (final orderId in orders.keys) {
        final order = orders[orderId];
        if (order != null && order['contactPhone'] == phone) {
          order['user'] = userId;
        }
      }
    }
  }

  String _generateRandomId() {
    final random = Random();
    return (100000 + random.nextInt(900000)).toString();
  }
}
