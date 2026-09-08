import 'package:flutter_test/flutter_test.dart';
import 'package:tiffin_service_app/features/orders/data/orders_repository.dart';

void main() {
  group('OrderModel Tiffin Tracking Calculations', () {
    test('future subscriptions return zero delivered meals', () {
      final order = OrderModel(
        id: 'test_id_1',
        frequency: 'weekly',
        quantity: 1,
        startDate: DateTime.now().add(const Duration(days: 2)),
        deliverySlot: 'lunch',
        contactPhone: '9999999999',
        houseNo: '10/482',
        area: 'Kalyanpur',
        landmark: 'Near Temple',
        pricePerMeal: 80.0,
        mealsCount: 5, // 5 days for weekly
        totalAmount: 400.0,
        discountAmount: 0.0,
        finalAmount: 400.0,
        paymentStatus: 'paid',
        orderStatus: 'confirmed',
        skippedDates: [],
        skippedSlots: [],
        createdAt: DateTime.now(),
      );

      expect(order.totalMeals, equals(5));
      expect(order.deliveredMeals, equals(0));
      expect(order.remainingMeals, equals(5));
      expect(order.progressPercent, equals(0.0));
    });

    test('correctly calculates total meals based on slots', () {
      final lunchOrder = OrderModel(
        id: 'test_id_2',
        frequency: 'weekly',
        quantity: 1,
        startDate: DateTime.now(),
        deliverySlot: 'lunch',
        contactPhone: '9999999999',
        houseNo: '10/482',
        area: 'Kalyanpur',
        landmark: 'Near Temple',
        pricePerMeal: 80.0,
        mealsCount: 5,
        totalAmount: 400.0,
        discountAmount: 0.0,
        finalAmount: 400.0,
        paymentStatus: 'paid',
        orderStatus: 'confirmed',
        skippedDates: [],
        skippedSlots: [],
        createdAt: DateTime.now(),
      );

      final bothSlotsOrder = OrderModel(
        id: 'test_id_3',
        frequency: 'weekly',
        quantity: 2,
        startDate: DateTime.now(),
        deliverySlot: 'both',
        contactPhone: '9999999999',
        houseNo: '10/482',
        area: 'Kalyanpur',
        landmark: 'Near Temple',
        pricePerMeal: 80.0,
        mealsCount: 5,
        totalAmount: 800.0,
        discountAmount: 0.0,
        finalAmount: 800.0,
        paymentStatus: 'paid',
        orderStatus: 'confirmed',
        skippedDates: [],
        skippedSlots: [],
        createdAt: DateTime.now(),
      );

      expect(lunchOrder.totalMeals, equals(5));
      expect(bothSlotsOrder.totalMeals, equals(10));
    });

    test('isDeliveryDay resolves correct delivery days', () {
      // 2026-08-30 is Sunday (date.weekday = 7)
      // 2026-08-31 is Monday (date.weekday = 1)
      final sunday = DateTime(2026, 8, 30);
      final monday = DateTime(2026, 8, 31);
      final saturday = DateTime(2026, 9, 5);

      // Mon-Fri frequencies (weekly, monthly, _5) should return false for Sunday/Saturday
      expect(OrderModel.isDeliveryDay(sunday, 'weekly'), isFalse);
      expect(OrderModel.isDeliveryDay(monday, 'weekly'), isTrue);
      expect(OrderModel.isDeliveryDay(saturday, 'weekly'), isFalse);

      // Mon-Sat frequencies (_6) should return true for Saturday, false for Sunday
      expect(OrderModel.isDeliveryDay(sunday, 'daily_6'), isFalse);
      expect(OrderModel.isDeliveryDay(monday, 'daily_6'), isTrue);
      expect(OrderModel.isDeliveryDay(saturday, 'daily_6'), isTrue);

      // Mon-Sun frequencies (daily) should return true always
      expect(OrderModel.isDeliveryDay(sunday, 'daily'), isTrue);
      expect(OrderModel.isDeliveryDay(monday, 'daily'), isTrue);
      expect(OrderModel.isDeliveryDay(saturday, 'daily'), isTrue);
    });

    test('resolves active stages correctly based on todayStatus', () {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      
      final orderWithManualStatus = OrderModel(
        id: 'test_manual_status',
        frequency: 'weekly',
        quantity: 1,
        startDate: now.subtract(const Duration(days: 2)),
        deliverySlot: 'lunch',
        contactPhone: '9999999999',
        houseNo: '10/482',
        area: 'Kalyanpur',
        landmark: 'Near Temple',
        pricePerMeal: 80.0,
        mealsCount: 5,
        totalAmount: 400.0,
        discountAmount: 0.0,
        finalAmount: 400.0,
        paymentStatus: 'paid',
        orderStatus: 'confirmed',
        skippedDates: [],
        skippedSlots: [],
        createdAt: now.subtract(const Duration(days: 2)),
        todayDeliveryStatus: 'out_for_delivery',
        todayDeliveryStatusDate: todayStr,
      );

      expect(orderWithManualStatus.todayActiveStage, equals(2));
      expect(orderWithManualStatus.todayStatusLabel, equals('OUT FOR DELIVERY'));
    });
  });
}
