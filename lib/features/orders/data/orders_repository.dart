import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

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
      id: map['_id'] ?? map['id'] ?? '',
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
      skippedDates: skippedRaw.map((d) => DateTime.parse(d)).toList(),
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
  final ApiClient _apiClient = ApiClient();

  // Storage for mock orders
  static List<OrderModel> _mockOrders = [];

  Future<List<OrderModel>> getUserOrders() async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Pre-seed some mock orders if list is empty
      if (_mockOrders.isEmpty) {
        _mockOrders = [
          // Active weekly plan
          OrderModel(
            id: 'mock_ord_901',
            frequency: 'weekly',
            quantity: 1,
            startDate: DateTime.now().subtract(const Duration(days: 1)),
            deliverySlot: 'lunch',
            contactPhone: '9876543210',
            pricePerMeal: 80.0,
            mealsCount: 7,
            totalAmount: 560.0,
            discountAmount: 50.0,
            finalAmount: 510.0,
            paymentStatus: 'paid',
            orderStatus: 'confirmed',
            skippedDates: [],
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
          // Past one-time plan (completed)
          OrderModel(
            id: 'mock_ord_902',
            frequency: 'one-time',
            quantity: 2,
            startDate: DateTime.now().subtract(const Duration(days: 5)),
            deliverySlot: 'dinner',
            contactPhone: '9876543210',
            pricePerMeal: 80.0,
            mealsCount: 1,
            totalAmount: 160.0,
            discountAmount: 0.0,
            finalAmount: 160.0,
            paymentStatus: 'paid',
            orderStatus: 'confirmed',
            skippedDates: [],
            createdAt: DateTime.now().subtract(const Duration(days: 5)),
          ),
        ];
      }
      
      return List.from(_mockOrders);
    } else {
      final response = await _apiClient.get('/orders/my-orders');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ordersList = data['orders'] ?? [];
        return ordersList.map((o) => OrderModel.fromMap(o)).toList();
      } else {
        throw Exception('Failed to fetch user orders list');
      }
    }
  }

  Future<OrderModel> skipDate(String orderId, DateTime date) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 600));
      
      final index = _mockOrders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        final order = _mockOrders[index];
        final cleanDate = DateTime(date.year, date.month, date.day);
        
        if (order.skippedDates.contains(cleanDate)) {
          throw Exception('This date is already skipped');
        }
        
        final updatedSkipped = List<DateTime>.from(order.skippedDates)..add(cleanDate);
        final updatedOrder = OrderModel(
          id: order.id,
          frequency: order.frequency,
          quantity: order.quantity,
          startDate: order.startDate,
          deliverySlot: order.deliverySlot,
          contactPhone: order.contactPhone,
          pricePerMeal: order.pricePerMeal,
          mealsCount: order.mealsCount,
          totalAmount: order.totalAmount,
          discountAmount: order.discountAmount,
          finalAmount: order.finalAmount,
          paymentStatus: order.paymentStatus,
          orderStatus: order.orderStatus,
          skippedDates: updatedSkipped,
          createdAt: order.createdAt,
        );
        
        _mockOrders[index] = updatedOrder;
        return updatedOrder;
      }
      throw Exception('Order not found');
    } else {
      final response = await _apiClient.post('/orders/skip', {
        'orderId': orderId,
        'date': date.toIso8601String(),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return OrderModel.fromMap(data['order']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Failed to skip delivery slot');
      }
    }
  }

  // Admin orders utility (called by admin dashboard)
  Future<List<OrderModel>> adminGetAllOrders() async {
    if (ApiConstants.useMockApi) {
      // Return local orders
      return getUserOrders();
    } else {
      final response = await _apiClient.get('/admin/orders');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List ordersList = data['orders'] ?? [];
        return ordersList.map((o) => OrderModel.fromMap(o)).toList();
      } else {
        throw Exception('Failed to retrieve system order records');
      }
    }
  }

  // Admin status update utility
  Future<void> adminUpdateStatus(String orderId, String status) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 500));
      final idx = _mockOrders.indexWhere((o) => o.id == orderId);
      if (idx != -1) {
        final o = _mockOrders[idx];
        _mockOrders[idx] = OrderModel(
          id: o.id,
          frequency: o.frequency,
          quantity: o.quantity,
          startDate: o.startDate,
          deliverySlot: o.deliverySlot,
          contactPhone: o.contactPhone,
          pricePerMeal: o.pricePerMeal,
          mealsCount: o.mealsCount,
          totalAmount: o.totalAmount,
          discountAmount: o.discountAmount,
          finalAmount: o.finalAmount,
          paymentStatus: o.paymentStatus,
          orderStatus: status == 'cancelled' ? 'cancelled' : 'confirmed',
          skippedDates: o.skippedDates,
          createdAt: o.createdAt,
        );
      }
    } else {
      final response = await _apiClient.put('/admin/orders/$orderId/status', {
        'orderStatus': status,
      });
      if (response.statusCode != 200) {
        throw Exception('Failed to update order status');
      }
    }
  }
}
