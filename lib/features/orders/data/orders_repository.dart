import '../../../core/services/firebase_service.dart';
import '../../auth/data/auth_repository.dart';

class OrderModel {
  final String id;
  final String frequency;
  final int quantity;
  final DateTime startDate;
  final String deliverySlot;
  final String contactPhone;
  final double pricePerMeal;
  final int mealsCount;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final String paymentStatus;
  final String orderStatus;
  final List<DateTime> skippedDates;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.frequency,
    required this.quantity,
    required this.startDate,
    required this.deliverySlot,
    required this.contactPhone,
    required this.pricePerMeal,
    required this.mealsCount,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    required this.paymentStatus,
    required this.orderStatus,
    required this.skippedDates,
    required this.createdAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map) {
    final skippedRaw = map['skippedDates'] as List? ?? [];
    return OrderModel(
      id: map['id'] ?? '',
      frequency: map['frequency'] ?? 'one-time',
      quantity: map['quantity'] ?? 1,
      startDate: DateTime.parse(map['startDate']),
      deliverySlot: map['deliverySlot'] ?? 'lunch',
      contactPhone: map['contactPhone'] ?? '',
      pricePerMeal: (map['pricePerMeal'] as num?)?.toDouble() ?? 80.0,
      mealsCount: map['mealsCount'] ?? 1,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 80.0,
      discountAmount: (map['discountAmount'] as num?)?.toDouble() ?? 0.0,
      finalAmount: (map['finalAmount'] as num?)?.toDouble() ?? 80.0,
      paymentStatus: map['paymentStatus'] ?? 'pending',
      orderStatus: map['orderStatus'] ?? 'confirmed',
      skippedDates: skippedRaw.map((d) => DateTime.parse(d as String)).toList(),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
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
      'pricePerMeal': pricePerMeal,
      'mealsCount': mealsCount,
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'finalAmount': finalAmount,
      'paymentStatus': paymentStatus,
      'orderStatus': orderStatus,
      'skippedDates': skippedDates.map((d) => d.toIso8601String()).toList(),
      'createdAt': createdAt.toIso8601String(),
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
}
