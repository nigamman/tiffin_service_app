import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/notification_overlay.dart';

class NotificationService {
  final BuildContext context;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  StreamSubscription<QuerySnapshot>? _couponSubscription;
  StreamSubscription<QuerySnapshot>? _ordersSubscription;
  StreamSubscription<QuerySnapshot>? _customSubscription;

  // Track coupon IDs loaded at startup to only notify for *newly* added coupons
  final Set<String> _existingCoupons = {};
  bool _couponsInitialized = false;

  // Track previous order statuses to prevent duplicate notifications and only trigger on status *changes*
  final Map<String, String> _previousOrderStatuses = {};
  bool _ordersInitialized = false;

  // Track custom notifications
  final Set<String> _existingCustomNotifications = {};
  bool _customInitialized = false;

  NotificationService(this.context);

  void startListeningToCoupons() {
    _couponSubscription?.cancel();
    _couponSubscription = _firestore.collection('coupons').snapshots().listen((snapshot) {
      if (!_couponsInitialized) {
        // First fetch: store all existing coupon IDs so we don't trigger alerts for them
        for (var doc in snapshot.docs) {
          _existingCoupons.add(doc.id);
        }
        _couponsInitialized = true;
        return;
      }

      // Subsequent changes: look for added documents
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          final couponId = doc.id;

          if (!_existingCoupons.contains(couponId)) {
            _existingCoupons.add(couponId);
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null && data['active'] == true) {
              final code = data['code'] ?? 'SPECIAL';
              final discountType = data['discountType'] ?? 'fixed';
              final discountValue = data['discountValue'] ?? 0.0;
              final String valueText = discountType == 'percent'
                  ? "${(discountValue as num).toStringAsFixed(0)}%"
                  : "₹${(discountValue as num).toStringAsFixed(0)}";

              // Show overlay push notification!
              NotificationOverlay.show(
                context,
                title: "New Promo Code Added! 🎁",
                message: "Use code $code to save $valueText off your next tiffin order!",
                icon: Icons.local_offer,
              );
            }
          }
        }
      }
    });
  }

  void startListeningToOrders(String userPhone) {
    _ordersSubscription?.cancel();
    _ordersInitialized = false;
    _previousOrderStatuses.clear();

    // Listen only to active orders belonging to this user phone
    _ordersSubscription = _firestore
        .collection('orders')
        .where('contactPhone', isEqualTo: userPhone)
        .snapshots()
        .listen((snapshot) {
      if (!_ordersInitialized) {
        // Store baseline status at startup to only detect updates
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final String? status = data['todayDeliveryStatus'];
          final String? date = data['todayDeliveryStatusDate'];
          if (status != null && date != null) {
            _previousOrderStatuses[doc.id] = "${date}_$status";
          }
        }
        _ordersInitialized = true;
        return;
      }

      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.modified) {
          final doc = change.doc;
          final orderId = doc.id;
          final data = doc.data() as Map<String, dynamic>?;
          if (data == null) continue;

          final String? newStatus = data['todayDeliveryStatus'];
          final String? newStatusDate = data['todayDeliveryStatusDate'];
          
          if (newStatus != null && newStatusDate != null) {
            final newStatusKey = "${newStatusDate}_$newStatus";
            final previousKey = _previousOrderStatuses[orderId];

            if (newStatusKey != previousKey) {
              _previousOrderStatuses[orderId] = newStatusKey;

              // Only notify if status is out_for_delivery or delivered
              if (newStatus == 'out_for_delivery') {
                NotificationOverlay.show(
                  context,
                  title: "Tiffin Dispatched! 🛵",
                  message: "Your tiffin is out for delivery! Get ready for a delicious meal.",
                  icon: Icons.delivery_dining,
                );
              } else if (newStatus == 'delivered') {
                NotificationOverlay.show(
                  context,
                  title: "Tiffin Delivered! 🎉",
                  message: "Your fresh home tiffin has been delivered. Enjoy your meal!",
                  icon: Icons.assignment_turned_in,
                );
              }
            }
          }
        }
      }
    });
  }

  void stopListeningToOrders() {
    _ordersSubscription?.cancel();
    _ordersSubscription = null;
    _previousOrderStatuses.clear();
    _ordersInitialized = false;
  }

  void startListeningToCustomNotifications(String? userPhone) {
    _customSubscription?.cancel();
    _customInitialized = false;
    _existingCustomNotifications.clear();

    _customSubscription = _firestore
        .collection('notifications')
        .snapshots()
        .listen((snapshot) {
      if (!_customInitialized) {
        // Store baseline of existing notification IDs
        for (var doc in snapshot.docs) {
          _existingCustomNotifications.add(doc.id);
        }
        _customInitialized = true;
        return;
      }

      // Detect newly added announcements
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final doc = change.doc;
          final notificationId = doc.id;

          if (!_existingCustomNotifications.contains(notificationId)) {
            _existingCustomNotifications.add(notificationId);
            final data = doc.data() as Map<String, dynamic>?;
            if (data != null) {
              final target = data['target'] ?? 'all';
              final title = data['title'] ?? 'Announcement';
              final message = data['message'] ?? '';

              final bool isTargetAll = target == 'all';
              final bool isTargetMe = userPhone != null && target == userPhone;

              if (isTargetAll || isTargetMe) {
                NotificationOverlay.show(
                  context,
                  title: title,
                  message: message,
                  icon: Icons.campaign,
                );
              }
            }
          }
        }
      }
    });
  }

  void stopListeningToCustomNotifications() {
    _customSubscription?.cancel();
    _customSubscription = null;
    _existingCustomNotifications.clear();
    _customInitialized = false;
  }

  void dispose() {
    _couponSubscription?.cancel();
    _ordersSubscription?.cancel();
    _customSubscription?.cancel();
  }
}
