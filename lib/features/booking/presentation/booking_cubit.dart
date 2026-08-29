import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/booking_repository.dart';

class BookingState extends Equatable {
  final int step;
  final String frequency;
  final int quantity;
  final DateTime startDate;
  final String deliverySlot;
  final String houseNo;
  final String area;
  final String landmark;
  final String contactPhone;
  final String couponCode;
  final CouponResult? appliedCoupon;
  final bool isLoading;
  final String? error;
  final OrderCreateResult? orderResult;
  final bool paymentSuccess;

  const BookingState({
    this.step = 0,
    this.frequency = 'one-time',
    this.quantity = 1,
    required this.startDate,
    this.deliverySlot = 'lunch',
    this.houseNo = '',
    this.area = '',
    this.landmark = '',
    this.contactPhone = '',
    this.couponCode = '',
    this.appliedCoupon,
    this.isLoading = false,
    this.error,
    this.orderResult,
    this.paymentSuccess = false,
  });

  BookingState copyWith({
    int? step,
    String? frequency,
    int? quantity,
    DateTime? startDate,
    String? deliverySlot,
    String? houseNo,
    String? area,
    String? landmark,
    String? contactPhone,
    String? couponCode,
    CouponResult? Function()? appliedCoupon,
    bool? isLoading,
    String? Function()? error,
    OrderCreateResult? Function()? orderResult,
    bool? paymentSuccess,
  }) {
    return BookingState(
      step: step ?? this.step,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      startDate: startDate ?? this.startDate,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      houseNo: houseNo ?? this.houseNo,
      area: area ?? this.area,
      landmark: landmark ?? this.landmark,
      contactPhone: contactPhone ?? this.contactPhone,
      couponCode: couponCode ?? this.couponCode,
      appliedCoupon: appliedCoupon != null ? appliedCoupon() : this.appliedCoupon,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      orderResult: orderResult != null ? orderResult() : this.orderResult,
      paymentSuccess: paymentSuccess ?? this.paymentSuccess,
    );
  }

  @override
  List<Object?> get props => [
        step,
        frequency,
        quantity,
        startDate,
        deliverySlot,
        houseNo,
        area,
        landmark,
        contactPhone,
        couponCode,
        appliedCoupon,
        isLoading,
        error,
        orderResult,
        paymentSuccess,
      ];
}

class BookingCubit extends Cubit<BookingState> {
  final BookingRepository _repository = BookingRepository();

  BookingCubit({String initialSlot = 'lunch'})
      : super(BookingState(
          startDate: DateTime.now().add(const Duration(days: 1)),
          deliverySlot: initialSlot,
        ));

  void setFrequency(String freq) {
    emit(state.copyWith(frequency: freq, error: () => null));
  }

  void updateMealDetails(int qty, DateTime date, String slot) {
    emit(state.copyWith(
      quantity: qty,
      startDate: date,
      deliverySlot: slot,
      error: () => null,
    ));
  }

  void setAddressDetails({
    required String houseNo,
    required String area,
    required String landmark,
    required String phone,
  }) {
    emit(state.copyWith(
      houseNo: houseNo,
      area: area,
      landmark: landmark,
      contactPhone: phone,
      error: () => null,
    ));
  }

  Future<void> applyCoupon(String code, double orderValue) async {
    if (code.trim().isEmpty) return;
    emit(state.copyWith(isLoading: true, error: () => null));
    try {
      final result = await _repository.validateCoupon(code, orderValue);
      if (result.isValid) {
        emit(state.copyWith(
          appliedCoupon: () => result,
          couponCode: code.toUpperCase(),
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          error: () => result.message,
          appliedCoupon: () => null,
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        error: () => e.toString(),
        appliedCoupon: () => null,
        isLoading: false,
      ));
    }
  }

  void removeCoupon() {
    emit(state.copyWith(
      appliedCoupon: () => null,
      couponCode: '',
      error: () => null,
    ));
  }

  Future<void> checkout() async {
    emit(state.copyWith(isLoading: true, error: () => null));
    try {
      final res = await _repository.createOrder(
        frequency: state.frequency,
        quantity: state.quantity,
        startDate: state.startDate.toIso8601String(),
        deliverySlot: state.deliverySlot,
        houseNo: state.houseNo,
        area: state.area,
        landmark: state.landmark,
        contactPhone: state.contactPhone,
        couponCode: state.appliedCoupon?.code,
      );
      
      emit(state.copyWith(
        orderResult: () => res,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        error: () => e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  Future<void> verifyPaymentSignature({
    required String razorpayPaymentId,
    String? signature,
  }) async {
    final orderRes = state.orderResult;
    if (orderRes == null) return;

    emit(state.copyWith(isLoading: true, error: () => null));
    try {
      final isVerified = await _repository.verifyPayment(
        orderId: orderRes.orderId,
        razorpayOrderId: orderRes.razorpayOrderId,
        razorpayPaymentId: razorpayPaymentId,
        razorpaySignature: signature,
      );

      if (isVerified) {
        emit(state.copyWith(
          paymentSuccess: true,
          isLoading: false,
        ));
      } else {
        emit(state.copyWith(
          error: () => 'Payment verification failed',
          isLoading: false,
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        error: () => e.toString().replaceAll('Exception: ', ''),
        isLoading: false,
      ));
    }
  }

  void nextStep() {
    emit(state.copyWith(step: state.step + 1));
  }

  void prevStep() {
    if (state.step > 0) {
      emit(state.copyWith(step: state.step - 1));
    }
  }

  void reset() {
    emit(BookingState(
      startDate: DateTime.now().add(const Duration(days: 1)),
    ));
  }
}
