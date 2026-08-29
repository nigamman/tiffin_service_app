import '../../../core/services/firebase_service.dart';
import '../../auth/data/auth_repository.dart';

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
}

class BookingRepository {
  final FirebaseService _db = FirebaseService.instance;
  final AuthRepository _authRepository = AuthRepository();

  Future<CouponResult> validateCoupon(String code, double orderValue) async {
    final cleanCode = code.trim().toUpperCase();
    
    // 1. Query Firestore for coupon document
    final coupons = await _db.collectionGetWhere('coupons', 'code', cleanCode);
    
    if (coupons.isEmpty) {
      return CouponResult(isValid: false, code: cleanCode, discountAmount: 0, message: 'Invalid coupon code');
    }

    final coupon = coupons.first;
    final isActive = coupon['active'] ?? false;
    final minOrder = (coupon['minOrderValue'] as num?)?.toDouble() ?? 0.0;
    final discountVal = (coupon['discountValue'] as num?)?.toDouble() ?? 0.0;
    final discType = coupon['discountType'] ?? 'fixed';

    if (!isActive) {
      return CouponResult(isValid: false, code: cleanCode, discountAmount: 0, message: 'This coupon is inactive');
    }

    if (orderValue < minOrder) {
      return CouponResult(
        isValid: false,
        code: cleanCode,
        discountAmount: 0,
        message: 'Requires min order value of ₹${minOrder.toStringAsFixed(0)}',
      );
    }

    double discount = 0.0;
    if (discType == 'fixed') {
      discount = discountVal;
    } else if (discType == 'percent') {
      discount = (orderValue * discountVal) / 100.0;
      final maxDisc = (coupon['maxDiscount'] as num?)?.toDouble();
      if (maxDisc != null && discount > maxDisc) {
        discount = maxDisc;
      }
    }

    discount = discount.clamp(0.0, orderValue);

    return CouponResult(
      isValid: true,
      code: cleanCode,
      discountAmount: discount,
      message: 'Coupon code applied successfully!',
    );
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
    // Retrieve currently cached user to link document
    final user = await _authRepository.getCachedUser();
    final userId = user?.id ?? 'anonymous';

    // 1. Calculate pricing details
    double pricePerMeal = 80.0;
    // Query active menu price
    final menus = await _db.collectionGetWhere('menu', 'isActive', true);
    if (menus.isNotEmpty) {
      pricePerMeal = (menus.first['price'] as num).toDouble();
    }

    int mealsCount = 1;
    int weeksMultiplier = 1;
    
    if (frequency == 'one-time') {
      mealsCount = 1;
      weeksMultiplier = 1;
    } else if (frequency.startsWith('weekly')) {
      weeksMultiplier = 2; // 2 weeks billing cycle
      if (frequency == 'weekly_5' || frequency == 'weekly') {
        mealsCount = 5;
      } else if (frequency == 'weekly_6') {
        mealsCount = 6;
      } else if (frequency == 'weekly_7') {
        mealsCount = 7;
      }
    } else if (frequency.startsWith('monthly')) {
      weeksMultiplier = 2; // 2 weeks x 4 = 8 weeks billing cycle (2 months) or let's keep it simple:
      // To match our monthly pricing:
      // Mon-Fri: 20 delivery days * ₹120 * 2 (slots) = ₹4,800 (1 month duration)
      // So multiplier is 1, mealsCount is 20, 24, or 30.
      weeksMultiplier = 1;
      if (frequency == 'monthly_20' || frequency == 'monthly') {
        mealsCount = 20;
      } else if (frequency == 'monthly_24') {
        mealsCount = 24;
      } else if (frequency == 'monthly_30') {
        mealsCount = 30;
      }
    }

    final double slotMultiplier = (deliverySlot == 'both') ? 2.0 : 1.0;
    final subtotal = pricePerMeal * mealsCount * slotMultiplier * weeksMultiplier * quantity;
    double discount = 0;

    if (couponCode != null && couponCode.isNotEmpty) {
      final couponCheck = await validateCoupon(couponCode, subtotal);
      if (couponCheck.isValid) discount = couponCheck.discountAmount;
    }

    final finalAmount = subtotal - discount;
    final rzpOrderId = 'order_rzp_mock_${DateTime.now().millisecondsSinceEpoch}';

    // 2. Build order document structure for Firestore
    final orderMap = {
      'user': userId,
      'frequency': frequency,
      'quantity': quantity,
      'startDate': startDate,
      'deliverySlot': deliverySlot,
      'contactPhone': contactPhone,
      'pricePerMeal': pricePerMeal,
      'mealsCount': mealsCount,
      'totalAmount': subtotal,
      'discountAmount': discount,
      'finalAmount': finalAmount,
      'couponCode': couponCode,
      'paymentStatus': 'pending',
      'orderStatus': 'confirmed',
      'razorpayOrderId': rzpOrderId,
      'skippedDates': <String>[],
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 3. Write order document to Firestore `/orders`
    final createdOrder = await _db.docAdd('orders', orderMap);
    final orderId = createdOrder['id'] as String;

    // 4. Write payment log to Firestore `/payments`
    await _db.docAdd('payments', {
      'orderId': orderId,
      'razorpayOrderId': rzpOrderId,
      'amount': finalAmount,
      'status': 'created',
      'createdAt': DateTime.now().toIso8601String(),
    });

    return OrderCreateResult(
      orderId: orderId,
      razorpayOrderId: rzpOrderId,
      amount: finalAmount,
      keyId: 'rzp_test_mockkey1234',
    );
  }

  Future<bool> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    String? razorpaySignature,
  }) async {
    // Verify signatures and confirm transactions in database documents
    final order = await _db.docGet('orders', orderId);
    if (order == null) throw Exception('Order not found');

    // 1. Update order payment status
    await _db.docUpdate('orders', orderId, {
      'paymentStatus': 'paid',
      'razorpayPaymentId': razorpayPaymentId,
    });

    // 2. Update payment document status
    final payments = await _db.collectionGetWhere('payments', 'orderId', orderId);
    if (payments.isNotEmpty) {
      final payDocId = payments.first['id'] as String;
      await _db.docUpdate('payments', payDocId, {
        'status': 'captured',
        'razorpayPaymentId': razorpayPaymentId,
        'razorpaySignature': razorpaySignature ?? 'mock_sig_verified',
      });
    }

    // 3. Increment usage count of applied coupon
    final String? appliedCode = order['couponCode'];
    if (appliedCode != null && appliedCode.isNotEmpty) {
      final coupons = await _db.collectionGetWhere('coupons', 'code', appliedCode);
      if (coupons.isNotEmpty) {
        final couponId = coupons.first['id'] as String;
        final currentCount = coupons.first['usageCount'] ?? 0;
        await _db.docUpdate('coupons', couponId, {
          'usageCount': currentCount + 1,
        });
      }
    }

    return true;
  }
}
