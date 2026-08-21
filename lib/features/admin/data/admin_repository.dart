import '../../../core/services/firebase_service.dart';

class AdminAnalyticsModel {
  final int totalCustomers;
  final double totalRevenue;
  final int todayOrdersCount;
  final double todayRevenue;
  final int activeSubscribersCount;
  final List<Map<String, dynamic>> couponStats;

  AdminAnalyticsModel({
    required this.totalCustomers,
    required this.totalRevenue,
    required this.todayOrdersCount,
    required this.todayRevenue,
    required this.activeSubscribersCount,
    required this.couponStats,
  });
}

class CouponAdminModel {
  final String id;
  final String code;
  final String discountType;
  final double discountValue;
  final double minOrderValue;
  final bool active;
  final int usageCount;

  CouponAdminModel({
    required this.id,
    required this.code,
    required this.discountType,
    required this.discountValue,
    required this.minOrderValue,
    required this.active,
    required this.usageCount,
  });

  factory CouponAdminModel.fromMap(Map<String, dynamic> map) {
    return CouponAdminModel(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      discountType: map['discountType'] ?? 'fixed',
      discountValue: (map['discountValue'] as num?)?.toDouble() ?? 0.0,
      minOrderValue: (map['minOrderValue'] as num?)?.toDouble() ?? 0.0,
      active: map['active'] ?? true,
      usageCount: map['usageCount'] ?? 0,
    );
  }
}

class AdminRepository {
  final FirebaseService _db = FirebaseService.instance;

  Future<AdminAnalyticsModel> getDashboardAnalytics() async {
    // 1. Total Customers (non-admins)
    final allUsers = await _db.collectionGet('users');
    final totalCustomers = allUsers.where((u) => u['isAdmin'] != true).length;

    // 2. Orders & Revenue Calculation
    final allOrders = await _db.collectionGet('orders');
    final paidOrders = allOrders.where((o) => o['paymentStatus'] == 'paid').toList();
    final totalRevenue = paidOrders.fold<double>(0, (sum, o) => sum + (o['finalAmount'] as num).toDouble());

    // 3. Today's stats
    final startOfToday = DateTime.now();
    final startOfTodayNormalized = DateTime(startOfToday.year, startOfToday.month, startOfToday.day);
    final endOfTodayNormalized = DateTime(startOfToday.year, startOfToday.month, startOfToday.day, 23, 59, 59, 999);

    final todayOrders = paidOrders.where((o) {
      final createdAt = DateTime.parse(o['createdAt']);
      return createdAt.isAfter(startOfTodayNormalized) && createdAt.isBefore(endOfTodayNormalized);
    }).toList();

    final todayOrdersCount = todayOrders.length;
    final todayRevenue = todayOrders.fold<double>(0, (sum, o) => sum + (o['finalAmount'] as num).toDouble());

    // 4. Active Recurring Subscriptions
    final activeSubscribersCount = paidOrders.where((o) {
      return o['frequency'] != 'one-time' && o['orderStatus'] == 'confirmed';
    }).length;

    // 5. Coupon Stats
    final allCoupons = await _db.collectionGet('coupons');
    final sortedCoupons = List<Map<String, dynamic>>.from(allCoupons)
      ..sort((a, b) => (b['usageCount'] as int).compareTo(a['usageCount'] as int));
    
    final couponStats = sortedCoupons.take(5).map((c) => {
      'code': c['code'] as String,
      'usageCount': c['usageCount'] as int,
    }).toList();

    return AdminAnalyticsModel(
      totalCustomers: totalCustomers,
      totalRevenue: totalRevenue,
      todayOrdersCount: todayOrdersCount,
      todayRevenue: todayRevenue,
      activeSubscribersCount: activeSubscribersCount,
      couponStats: couponStats,
    );
  }

  Future<List<CouponAdminModel>> getCoupons() async {
    final coupons = await _db.collectionGet('coupons');
    return coupons.map((c) => CouponAdminModel.fromMap(c)).toList();
  }

  Future<CouponAdminModel> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    required double minOrderValue,
  }) async {
    final cleanCode = code.toUpperCase().trim();
    
    // Check if code exists
    final existing = await _db.collectionGetWhere('coupons', 'code', cleanCode);
    if (existing.isNotEmpty) {
      throw Exception('A coupon code with this name already exists');
    }

    final newCouponMap = {
      'code': cleanCode,
      'discountType': discountType,
      'discountValue': discountValue,
      'minOrderValue': minOrderValue,
      'active': true,
      'usageCount': 0,
      'createdAt': DateTime.now().toIso8601String(),
    };

    final createdDoc = await _db.docAdd('coupons', newCouponMap);
    return CouponAdminModel.fromMap(createdDoc);
  }

  Future<void> toggleCoupon(String id) async {
    final coupon = await _db.docGet('coupons', id);
    if (coupon == null) throw Exception('Coupon code not found');
    
    final currentActive = coupon['active'] ?? false;
    await _db.docUpdate('coupons', id, {
      'active': !currentActive,
    });
  }
}
