import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class CouponResult {
  final bool isValid;
  final String code;
  final double discountAmount;
  final String message;

  CouponResult({
    required this.isValid,
    required this.code,
    required this.discountAmount,
    required this.message,
  });

  factory CouponResult.fromMap(Map<String, dynamic> map) {
    return CouponResult(
      isValid: map['isValid'] ?? false,
      code: map['code'] ?? '',
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      message: map['message'] ?? '',
    );
  }
}

class OrderCreateResult {
  final String orderId;
  final String razorpayOrderId;
  final double amount;
  final String keyId;

  OrderCreateResult({
    required this.orderId,
    required this.razorpayOrderId,
    required this.amount,
    required this.keyId,
  });

  factory OrderCreateResult.fromMap(Map<String, dynamic> map) {
    return OrderCreateResult(
      orderId: map['orderId'] ?? '',
      razorpayOrderId: map['razorpayOrderId'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      keyId: map['keyId'] ?? '',
    );
  }
}

class BookingRepository {
  final ApiClient _apiClient = ApiClient();

  Future<CouponResult> validateCoupon(String code, double orderValue) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      
      final cleanCode = code.trim().toUpperCase();
      double discount = 0.0;
      bool isValid = false;
      String msg = '';

      if (cleanCode == 'FIRSTTIFFIN') {
        if (orderValue >= 80.0) {
          discount = 30.0;
          isValid = true;
          msg = 'FIRSTTIFFIN applied! ₹30 OFF';
        } else {
          msg = 'Code requires min order of ₹80';
        }
      } else if (cleanCode == 'KANPUR50') {
        if (orderValue >= 200.0) {
          discount = 50.0;
          isValid = true;
          msg = 'KANPUR50 applied! ₹50 OFF';
        } else {
          msg = 'Code requires min order of ₹200';
        }
      } else if (cleanCode == 'WELCOME20') {
        if (orderValue >= 80.0) {
          discount = (orderValue * 0.20).clamp(0.0, 100.0);
          isValid = true;
          msg = 'WELCOME20 applied! 20% OFF';
        } else {
          msg = 'Code requires min order of ₹80';
        }
      } else if (cleanCode == 'WEEKLY50') {
        if (orderValue >= 500.0) {
          discount = 50.0;
          isValid = true;
          msg = 'WEEKLY50 applied! ₹50 OFF';
        } else {
          msg = 'Code requires min order of ₹500';
        }
      } else {
        msg = 'Invalid coupon code';
      }

      return CouponResult(
        isValid: isValid,
        code: cleanCode,
        discountAmount: discount,
        message: msg,
      );
    } else {
      try {
        final response = await _apiClient.post('/coupons/validate', {
          'code': code,
          'orderValue': orderValue,
        });
        
        final data = jsonDecode(response.body);
        return CouponResult.fromMap(data);
      } catch (e) {
        return CouponResult(
          isValid: false,
          code: code,
          discountAmount: 0.0,
          message: 'Error validating coupon: $e',
        );
      }
    }
  }

  Future<OrderCreateResult> createOrder({
    required String frequency,
    required int quantity,
    required String startDate,
    required String deliverySlot,
    required String houseNo,
    required String area,
    required String landmark,
    required String contactPhone,
    String? couponCode,
  }) async {
    final payload = {
      'frequency': frequency,
      'quantity': quantity,
      'startDate': startDate,
      'deliverySlot': deliverySlot,
      'deliveryAddress': {
        'houseNo': houseNo,
        'area': area,
        'landmark': landmark,
      },
      'contactPhone': contactPhone,
      if (couponCode != null && couponCode.isNotEmpty) 'couponCode': couponCode,
    };

    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      // Calculate mock final price locally
      double pricePerMeal = 80.0;
      int mealsCount = 1;
      if (frequency == 'weekly' || frequency == 'daily') mealsCount = 7;
      if (frequency == 'monthly') mealsCount = 30;
      double total = pricePerMeal * mealsCount * quantity;

      // Mock coupon subtract
      double discount = 0;
      if (couponCode != null) {
        final res = await validateCoupon(couponCode, total);
        if (res.isValid) discount = res.discountAmount;
      }
      
      final finalAmount = total - discount;

      return OrderCreateResult(
        orderId: 'order_db_mock_${Math.randomString()}',
        razorpayOrderId: 'order_rzp_mock_${Math.randomString()}',
        amount: finalAmount,
        keyId: 'rzp_test_mockkey1234',
      );
    } else {
      final response = await _apiClient.post('/orders', payload);
      
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return OrderCreateResult.fromMap(data);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to initiate order placement');
      }
    }
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 600));
      return true;
    } else {
      final response = await _apiClient.post('/orders/verify', {
        'orderId': orderId,
        'razorpayOrderId': razorpayOrderId,
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature ?? 'mock_sig_123',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['verified'] ?? false;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to verify transaction signature');
      }
    }
  }
}

class Math {
  static String randomString() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(6);
  }
}
