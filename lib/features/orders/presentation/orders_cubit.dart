import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/orders_repository.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<OrderModel> activeOrders;
  final List<OrderModel> orderHistory;

  const OrdersLoaded({required this.activeOrders, required this.orderHistory});

  @override
  List<Object?> get props => [activeOrders, orderHistory];
}

class OrdersError extends OrdersState {
  final String message;
  const OrdersError(this.message);

  @override
  List<Object?> get props => [message];
}

class OrdersCubit extends Cubit<OrdersState> {
  final OrdersRepository _repository = OrdersRepository();

  OrdersCubit() : super(OrdersInitial());

  Future<void> loadOrders() async {
    emit(OrdersLoading());
    try {
      final allOrders = await _repository.getUserOrders();
      
      // Group by active vs history
      final active = allOrders.where((o) => o.orderStatus != 'cancelled' && o.remainingMeals > 0).toList();
      final history = allOrders.where((o) => o.orderStatus == 'cancelled' || o.remainingMeals == 0).toList();

      emit(OrdersLoaded(activeOrders: active, orderHistory: history));
    } catch (e) {
      emit(OrdersError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> skipDeliveryDate(String orderId, DateTime date) async {
    try {
      await _repository.skipDate(orderId, date);
      // Reload orders list to update UI state
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString().replaceAll('Exception: ', '')));
      // Reload to ensure state is synchronized
      await loadOrders();
    }
  }

  Future<void> skipSlot(String orderId, String slotKey) async {
    try {
      await _repository.skipSlot(orderId, slotKey);
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString().replaceAll('Exception: ', '')));
      await loadOrders();
    }
  }

  Future<void> unskipSlot(String orderId, String slotKey) async {
    try {
      await _repository.unskipSlot(orderId, slotKey);
      await loadOrders();
    } catch (e) {
      emit(OrdersError(e.toString().replaceAll('Exception: ', '')));
      await loadOrders();
    }
  }
}
