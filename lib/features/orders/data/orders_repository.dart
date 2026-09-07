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

  int get deliveredMeals {
    final now = DateTime.now();
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final startLocal = startDate.toLocal();
    final startNormalized = DateTime(startLocal.year, startLocal.month, startLocal.day);

    if (todayNormalized.isBefore(startNormalized)) {
      return 0;
    }

    int totalElapsedSlots = 0;
    final currentHour = now.hour;
    final currentMinute = now.minute;
    final currentFloatTime = currentHour + (currentMinute / 60.0);

    final int totalDays = todayNormalized.difference(startNormalized).inDays;
    for (int i = 0; i <= totalDays; i++) {
      final checkDate = startNormalized.add(Duration(days: i));
      if (isDeliveryDay(checkDate, frequency)) {
        if (checkDate.isBefore(todayNormalized)) {
          // Past day: all slots elapsed
          totalElapsedSlots += (deliverySlot == 'both' ? 2 : 1);
        } else if (checkDate.isAtSameMomentAs(todayNormalized)) {
          // Today: check which slots have actually finished delivery window
          if (deliverySlot == 'lunch') {
            if (currentFloatTime >= 13.5) { // Lunch ends at 1:30 PM (13.5)
              totalElapsedSlots += 1;
            }
          } else if (deliverySlot == 'dinner') {
            if (currentFloatTime >= 21.0) { // Dinner ends at 9:00 PM (21.0)
              totalElapsedSlots += 1;
            }
          } else if (deliverySlot == 'both') {
            if (currentFloatTime >= 21.0) {
              totalElapsedSlots += 2; // both lunch and dinner ended
            } else if (currentFloatTime >= 13.5) {
              totalElapsedSlots += 1; // only lunch ended
            }
          }
        }
      }
    }

    // Build a Set of unique skipped meal slot keys to avoid double-counting between skippedDates and skippedSlots
    final Set<String> uniqueSkippedSlotKeys = {};

    for (final d in skippedDates) {
      final dLocal = d.toLocal();
      final dateNorm = DateTime(dLocal.year, dLocal.month, dLocal.day);
      if (!dateNorm.isAfter(todayNormalized)) {
        final dateStr = DateFormat('yyyy-MM-dd').format(dateNorm);
        if (deliverySlot == 'both') {
          uniqueSkippedSlotKeys.add('${dateStr}_lunch');
          uniqueSkippedSlotKeys.add('${dateStr}_dinner');
        } else {
          uniqueSkippedSlotKeys.add('${dateStr}_$deliverySlot');
        }
      }
    }

    for (final slotKey in skippedSlots) {
      try {
        final dateStr = slotKey.split('_')[0];
        final slotDate = DateTime.parse(dateStr).toLocal();
        final dateNorm = DateTime(slotDate.year, slotDate.month, slotDate.day);
        if (!dateNorm.isAfter(todayNormalized)) {
          uniqueSkippedSlotKeys.add(slotKey);
        }
      } catch (_) {}
    }

    final totalSkips = uniqueSkippedSlotKeys.length;
    final effectiveDelivered = totalElapsedSlots - totalSkips;
    return effectiveDelivered.clamp(0, totalMeals);
  }

  int get remainingMeals {
    return (totalMeals - deliveredMeals).clamp(0, totalMeals);
  }

  double get progressPercent {
    return totalMeals > 0 ? remainingMeals / totalMeals : 0.0;
  }

  bool isScheduledForDate(DateTime targetDate) {
    if (orderStatus == 'cancelled') return false;
    if (remainingMeals <= 0) return false;

    final targetNormalized = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final targetStr = DateFormat('yyyy-MM-dd').format(targetDate);

    final startLocal = startDate.toLocal();
    final startNormalized = DateTime(startLocal.year, startLocal.month, startLocal.day);

    if (targetNormalized.isBefore(startNormalized)) return false;

    // Check full-day skipped dates
    final isDaySkipped = skippedDates.any((d) {
      final dLocal = d.toLocal();
      return DateTime(dLocal.year, dLocal.month, dLocal.day)
          .isAtSameMomentAs(targetNormalized);
    });
    if (isDaySkipped) return false;

    // Check slot skips
    if (deliverySlot == 'lunch' && skippedSlots.contains('${targetStr}_lunch')) {
      return false;
    }
    if (deliverySlot == 'dinner' && skippedSlots.contains('${targetStr}_dinner')) {
      return false;
    }
    if (deliverySlot == 'both' &&
        skippedSlots.contains('${targetStr}_lunch') &&
        skippedSlots.contains('${targetStr}_dinner')) {
      return false;
    }

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

  Future<OrderModel> skipDate(String orderId, DateTime date) async {
    final order = await _db.docGet('orders', orderId);
    if (order == null) throw Exception('Order not found');

    final List skippedRaw = order['skippedDates'] as List? ?? [];
    final List<String> skippedStrings = List<String>.from(skippedRaw);
    
    final cleanDateString = DateTime(date.year, date.month, date.day).toIso8601String();
    
    if (skippedStrings.contains(cleanDateString)) {
      throw Exception('This date is already skipped');
    }

    skippedStrings.add(cleanDateString);

    // Update orders document in Firestore
    await _db.docUpdate('orders', orderId, {
      'skippedDates': skippedStrings,
    });

    final updatedDoc = await _db.docGet('orders', orderId);
    return OrderModel.fromMap(updatedDoc!);
  }

  Future<OrderModel> skipSlot(String orderId, String slotKey) async {
    final order = await _db.docGet('orders', orderId);
    if (order == null) throw Exception('Order not found');

    final List skippedRaw = order['skippedSlots'] as List? ?? [];
    final List<String> skippedStrings = List<String>.from(skippedRaw);
    
    if (skippedStrings.contains(slotKey)) {
      throw Exception('This slot is already skipped');
    }

    skippedStrings.add(slotKey);

    await _db.docUpdate('orders', orderId, {
      'skippedSlots': skippedStrings,
    });

    final updatedDoc = await _db.docGet('orders', orderId);
    return OrderModel.fromMap(updatedDoc!);
  }

  Future<OrderModel> unskipSlot(String orderId, String slotKey) async {
    final order = await _db.docGet('orders', orderId);
    if (order == null) throw Exception('Order not found');

    final List skippedRaw = order['skippedSlots'] as List? ?? [];
    final List<String> skippedStrings = List<String>.from(skippedRaw);
    
    if (!skippedStrings.contains(slotKey)) {
      throw Exception('This slot is not skipped');
    }

    skippedStrings.remove(slotKey);

    await _db.docUpdate('orders', orderId, {
      'skippedSlots': skippedStrings,
    });

    final updatedDoc = await _db.docGet('orders', orderId);
    return OrderModel.fromMap(updatedDoc!);
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
