import 'package:intl/intl.dart';
import '../../../core/services/firebase_service.dart';
import '../../auth/data/auth_repository.dart';

class OrderModel {
  final String id;
  final String frequency;
  final int quantity;
  final DateTime startDate;
  final String deliverySlot;
  final String contactPhone;
  final String houseNo;
  final String area;
  final String landmark;
  final String deliveryInstructions;
  final double pricePerMeal;
  final int mealsCount;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentStatus;
  final String orderStatus;
  final List<DateTime> skippedDates;
  final List<String> skippedSlots;
  final DateTime createdAt;
  final String? razorpayPaymentId;
  final String? todayDeliveryStatus;
  final String? todayDeliveryStatusDate;
  final String? todayLunchStatus;
  final String? todayLunchStatusDate;
  final String? todayDinnerStatus;
  final String? todayDinnerStatusDate;

  OrderModel({
    required this.id,
    required this.frequency,
    required this.quantity,
    required this.startDate,
    required this.deliverySlot,
    required this.contactPhone,
    this.houseNo = '',
    this.area = '',
    this.landmark = '',
    this.deliveryInstructions = '',
    required this.pricePerMeal,
    required this.mealsCount,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.skippedDates,
    required this.skippedSlots,
    required this.createdAt,
    this.razorpayPaymentId,
    this.todayDeliveryStatus,
    this.todayDeliveryStatusDate,
    this.todayLunchStatus,
    this.todayLunchStatusDate,
    this.todayDinnerStatus,
    this.todayDinnerStatusDate,
  });

  // GETTERS AND HELPERS
  int get totalMeals {
    final slotMultiplier = deliverySlot == 'both' ? 2 : 1;
    return mealsCount * slotMultiplier;
  }

  bool isSlotDelivered(DateTime date, String slot) {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final targetNorm = DateTime(date.year, date.month, date.day);
    final todayStr = DateFormat('yyyy-MM-dd').format(todayNormalized);

    if (targetNorm.isBefore(todayNormalized)) {
      return true;
    }

    if (targetNorm.isAtSameMomentAs(todayNormalized)) {
      final currentFloatTime = now.hour + (now.minute / 60.0);
      final isTimePassed = (slot == 'lunch' && currentFloatTime >= 13.5) ||
          (slot == 'dinner' && currentFloatTime >= 21.0);
      if (isTimePassed) return true;

      // Check slot-specific admin status updates
      if (slot == 'lunch') {
        if (todayLunchStatusDate == todayStr && todayLunchStatus?.toLowerCase() == 'delivered') {
          return true;
        }
      } else if (slot == 'dinner') {
        if (todayDinnerStatusDate == todayStr && todayDinnerStatus?.toLowerCase() == 'delivered') {
          return true;
        }
      }

      // Check general today delivery status admin update
      if (todayDeliveryStatusDate == todayStr && todayDeliveryStatus?.toLowerCase() == 'delivered') {
        if (deliverySlot == 'both') {
          if (slot == 'lunch') return true;
          if (slot == 'dinner' && now.hour >= 15) return true;
        } else if (deliverySlot == slot) {
          return true;
        }
      }
    }

    return false;
  }

  int get deliveredMeals {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final startLocal = startDate.toLocal();
    final startNormalized = DateTime(startLocal.year, startLocal.month, startLocal.day);

    if (todayNormalized.isBefore(startNormalized)) {
      return 0;
    }

    int totalElapsedSlots = 0;
    final int totalDays = todayNormalized.difference(startNormalized).inDays;
    for (int i = 0; i <= totalDays; i++) {
      final checkDate = startNormalized.add(Duration(days: i));
      if (isDeliveryDay(checkDate, frequency)) {
        if (deliverySlot == 'lunch') {
          if (isSlotDelivered(checkDate, 'lunch')) totalElapsedSlots += 1;
        } else if (deliverySlot == 'dinner') {
          if (isSlotDelivered(checkDate, 'dinner')) totalElapsedSlots += 1;
        } else if (deliverySlot == 'both') {
          if (isSlotDelivered(checkDate, 'lunch')) totalElapsedSlots += 1;
          if (isSlotDelivered(checkDate, 'dinner')) totalElapsedSlots += 1;
        }
      }
    }

    return totalElapsedSlots.clamp(0, totalMeals);
  }

  int get remainingMeals {
    return (totalMeals - deliveredMeals).clamp(0, totalMeals);
  }

  double get progressPercent {
    return totalMeals > 0 ? deliveredMeals / totalMeals : 0.0;
  }

  bool isScheduledForDate(DateTime targetDate) {
    if (orderStatus == 'cancelled') return false;
    if (remainingMeals <= 0) return false;

    final targetNormalized = DateTime(targetDate.year, targetDate.month, targetDate.day);

    final startLocal = startDate.toLocal();
    final startNormalized = DateTime(startLocal.year, startLocal.month, startLocal.day);

    if (targetNormalized.isBefore(startNormalized)) return false;

    if (frequency == 'one-time') {
      return startNormalized.isAtSameMomentAs(targetNormalized);
    }

    return isDeliveryDay(targetNormalized, frequency);
  }

  bool get isScheduledToday => isScheduledForDate(DateTime.now());

  int get todayActiveStage {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    
    // Determine relevant status field depending on time of day for 'both' slots vs single slot
    String? relevantStatus = todayDeliveryStatus;
    String? relevantStatusDate = todayDeliveryStatusDate;

    final isDinnerTime = (deliverySlot == 'both' && now.hour >= 15);
    if (isDinnerTime && todayDinnerStatus != null && todayDinnerStatusDate == todayStr) {
      relevantStatus = todayDinnerStatus;
      relevantStatusDate = todayDinnerStatusDate;
    } else if (!isDinnerTime && deliverySlot == 'both' && todayLunchStatus != null && todayLunchStatusDate == todayStr) {
      relevantStatus = todayLunchStatus;
      relevantStatusDate = todayLunchStatusDate;
    }
    
    if (relevantStatusDate == todayStr && relevantStatus != null) {
      final status = relevantStatus.toLowerCase();
      if (status == 'preparing' || status == 'cooking' || status == 'meal_preparing') {
        return 1;
      } else if (status == 'on_way' || status == 'out_for_delivery' || status == 'dispatched') {
        return 2;
      } else if (status == 'delivered') {
        return 3;
      } else {
        return 0; // Placed
      }
    }
    
    // Fallback to time-of-day logic (placed vs meal preparing)
    final hour = now.hour;
    final minute = now.minute;
    final double timeOfDay = hour + (minute / 60.0);

    if (deliverySlot == 'dinner') {
      if (timeOfDay >= 18.0) {
        return 1; // Meal Preparing
      }
      return 0; // Placed
    } else if (deliverySlot == 'lunch' || deliverySlot == 'both') {
      if (isDinnerTime) {
        if (timeOfDay >= 18.0) {
          return 1; // Meal Preparing for dinner
        }
        return 0; // Placed for dinner
      } else {
        if (timeOfDay >= 10.5) {
          return 1; // Meal Preparing for lunch
        }
        return 0; // Placed for lunch
      }
    }
    
    return 0; // Placed
  }

  String get todayStatusLabel {
    final stage = todayActiveStage;
    switch (stage) {
      case 1:
        return "MEAL PREPARING";
      case 2:
        return "OUT FOR DELIVERY";
      case 3:
        return "DELIVERED";
      default:
        return "PLACED";
    }
  }

  static bool isDeliveryDay(DateTime date, String frequency) {
    final weekday = date.weekday; // 1 = Monday, ..., 7 = Sunday
    
    if (frequency.contains('_5') || frequency == 'weekly' || frequency == 'monthly') {
      return weekday >= 1 && weekday <= 5;
    } else if (frequency.contains('_6')) {
      return weekday >= 1 && weekday <= 6;
    }
    return true;
  }

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final skippedRaw = map['skippedDates'] as List? ?? [];
    final skippedSlotsRaw = map['skippedSlots'] as List? ?? [];
    return OrderModel(
      id: map['id'] ?? '',
      frequency: map['frequency'] ?? 'one-time',
      quantity: map['quantity'] ?? 1,
      startDate: DateTime.parse(map['startDate']),
      deliverySlot: map['deliverySlot'] ?? 'lunch',
      contactPhone: map['contactPhone'] ?? '',
      houseNo: map['houseNo'] ?? '',
      area: map['area'] ?? '',
      landmark: map['landmark'] ?? '',
      deliveryInstructions: map['deliveryInstructions'] ?? '',
      pricePerMeal: (map['pricePerMeal'] as num?)?.toDouble() ?? 80.0,
      mealsCount: map['mealsCount'] ?? 1,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 80.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 80.0,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      orderStatus: map['orderStatus'] ?? 'confirmed',
      skippedDates: skippedRaw.map((d) => DateTime.parse(d as String)).toList(),
      skippedSlots: List<String>.from(skippedSlotsRaw),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      razorpayPaymentId: map['razorpayPaymentId'],
      todayDeliveryStatus: map['todayDeliveryStatus'],
      todayDeliveryStatusDate: map['todayDeliveryStatusDate'],
      todayLunchStatus: map['todayLunchStatus'],
      todayLunchStatusDate: map['todayLunchStatusDate'],
      todayDinnerStatus: map['todayDinnerStatus'],
      todayDinnerStatusDate: map['todayDinnerStatusDate'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'frequency': frequency,
      'quantity': quantity,
      'startDate': startDate.toIso8601String(),
      'deliverySlot': deliverySlot,
      'contactPhone': contactPhone,
      'houseNo': houseNo,
      'area': area,
      'landmark': landmark,
      'deliveryInstructions': deliveryInstructions,
      'pricePerMeal': pricePerMeal,
      'mealsCount': mealsCount,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'skippedDates': skippedDates.map((d) => d.toIso8601String()).toList(),
      'skippedSlots': skippedSlots,
      'createdAt': createdAt.toIso8601String(),
      'razorpayPaymentId': razorpayPaymentId,
      'todayDeliveryStatus': todayDeliveryStatus,
      'todayDeliveryStatusDate': todayDeliveryStatusDate,
      'todayLunchStatus': todayLunchStatus,
      'todayLunchStatusDate': todayLunchStatusDate,
      'todayDinnerStatus': todayDinnerStatus,
      'todayDinnerStatusDate': todayDinnerStatusDate,
    };
  }
}

class OrdersRepository {
  final FirebaseService _db = FirebaseService.instance;
  final AuthRepository _authRepository = AuthRepository();

  Future<List<OrderModel>> getUserOrders() async {
    final user = await _authRepository.getCachedUser();
    if (user == null) return [];

    // Query Firestore orders collection where user == userId and paymentStatus == paid
    final allOrders = await _db.collectionGetWhere('orders', 'user', user.id);
    final paidOrders = allOrders.where((o) => o['paymentStatus'] == 'paid').toList();
    
    return paidOrders.map((o) => OrderModel.fromMap(o)).toList();
  }

  // Admin access routines
  Future<List<OrderModel>> adminGetAllOrders() async {
    final allOrders = await _db.collectionGet('orders');
    final paidOrders = allOrders.where((o) => o['paymentStatus'] == 'paid').toList();
    return paidOrders.map((o) => OrderModel.fromMap(o)).toList();
  }

  Future<void> adminUpdateStatus(String orderId, String status) async {
    await _db.docUpdate('orders', orderId, {
      'orderStatus': status,
    });
  }

  Future<void> adminUpdateTodayDeliveryStatus(String orderId, String status, String dateStr, {String? slot}) async {
    final updates = <String, dynamic>{
      'todayDeliveryStatus': status,
      'todayDeliveryStatusDate': dateStr,
    };
    if (slot == 'lunch') {
      updates['todayLunchStatus'] = status;
      updates['todayLunchStatusDate'] = dateStr;
    } else if (slot == 'dinner') {
      updates['todayDinnerStatus'] = status;
      updates['todayDinnerStatusDate'] = dateStr;
    }
    await _db.docUpdate('orders', orderId, updates);
  }

  Future<void> adminUpdateAllTodayDeliveryStatus(String status, String dateStr, {String? slot}) async {
    final allOrders = await _db.collectionGet('orders');
    final paidOrders = allOrders.where((o) => o['paymentStatus'] == 'paid').map((o) => OrderModel.fromMap(o)).toList();
    for (final order in paidOrders) {
      if (order.isScheduledToday) {
        final updates = <String, dynamic>{
          'todayDeliveryStatus': status,
          'todayDeliveryStatusDate': dateStr,
        };
        if (slot != null || order.deliverySlot != 'both') {
          final s = slot ?? order.deliverySlot;
          if (s == 'lunch') {
            updates['todayLunchStatus'] = status;
            updates['todayLunchStatusDate'] = dateStr;
          } else if (s == 'dinner') {
            updates['todayDinnerStatus'] = status;
            updates['todayDinnerStatusDate'] = dateStr;
          }
        }
        await _db.docUpdate('orders', order.id, updates);
      }
    }
  }
}
