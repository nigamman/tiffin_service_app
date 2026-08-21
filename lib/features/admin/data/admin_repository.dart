import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

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

  factory AdminAnalyticsModel.fromMap(Map<String, dynamic> map) {
    return AdminAnalyticsModel(
      totalCustomers: map['totalCustomers'] ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      todayOrdersCount: map['todayOrdersCount'] ?? 0,
      todayRevenue: (map['todayRevenue'] as num?)?.toDouble() ?? 0.0,
      activeSubscribersCount: map['activeSubscribersCount'] ?? 0,
      couponStats: List<Map<String, dynamic>>.from(map['couponStats'] ?? []),
    );
  }
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
      id: map['_id'] ?? map['id'] ?? '',
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
  final ApiClient _apiClient = ApiClient();

  // Storage for mock coupons added in admin console
  static List<CouponAdminModel> _mockCoupons = [];

  Future<AdminAnalyticsModel> getDashboardAnalytics() async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      return AdminAnalyticsModel(
        totalCustomers: 48,
        totalRevenue: 24320.0,
        todayOrdersCount: 9,
        todayRevenue: 720.0,
        activeSubscribersCount: 14,
        couponStats: [
          {'code': 'FIRSTTIFFIN', 'usageCount': 22},
          {'code': 'KANPUR50', 'usageCount': 12},
          {'code': 'WELCOME20', 'usageCount': 8},
        ],
      );
    } else {
      final response = await _apiClient.get('/admin/analytics');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AdminAnalyticsModel.fromMap(data);
      } else {
        throw Exception('Failed to load system dashboard analytics');
      }
    }
  }

  Future<List<CouponAdminModel>> getCoupons() async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 400));
      if (_mockCoupons.isEmpty) {
        _mockCoupons = [
          CouponAdminModel(id: 'c1', code: 'FIRSTTIFFIN', discountType: 'fixed', discountValue: 30.0, minOrderValue: 80.0, active: true, usageCount: 22),
          CouponAdminModel(id: 'c2', code: 'KANPUR50', discountType: 'fixed', discountValue: 50.0, minOrderValue: 200.0, active: true, usageCount: 12),
          CouponAdminModel(id: 'c3', code: 'WELCOME20', discountType: 'percent', discountValue: 20.0, minOrderValue: 80.0, active: true, usageCount: 8),
        ];
      }
      return List.from(_mockCoupons);
    } else {
      final response = await _apiClient.get('/coupons');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List list = data['coupons'] ?? [];
        return list.map((c) => CouponAdminModel.fromMap(c)).toList();
      } else {
        throw Exception('Failed to load coupon registry');
      }
    }
  }

  Future<CouponAdminModel> createCoupon({
    required String code,
    required String discountType,
    required double discountValue,
    required double minOrderValue,
  }) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      final newCoupon = CouponAdminModel(
        id: 'mock_cp_${DateTime.now().millisecondsSinceEpoch}',
        code: code.toUpperCase(),
        discountType: discountType,
        discountValue: discountValue,
        minOrderValue: minOrderValue,
        active: true,
        usageCount: 0,
      );
      _mockCoupons.add(newCoupon);
      return newCoupon;
    } else {
      final response = await _apiClient.post('/coupons', {
        'code': code.toUpperCase(),
        'discountType': discountType,
        'discountValue': discountValue,
        'minOrderValue': minOrderValue,
      });

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return CouponAdminModel.fromMap(data['coupon']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to register new coupon');
      }
    }
  }

  Future<void> toggleCoupon(String id) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 400));
      final idx = _mockCoupons.indexWhere((c) => c.id == id);
      if (idx != -1) {
        final c = _mockCoupons[idx];
        _mockCoupons[idx] = CouponAdminModel(
          id: c.id,
          code: c.code,
          discountType: c.discountType,
          discountValue: c.discountValue,
          minOrderValue: c.minOrderValue,
          active: !c.active,
          usageCount: c.usageCount,
        );
      }
    } else {
      final response = await _apiClient.put('/coupons/$id/toggle', {});
      if (response.statusCode != 200) {
        throw Exception('Failed to toggle coupon active state');
      }
    }
  }
}
