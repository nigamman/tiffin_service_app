import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/menu_repository.dart';

abstract class MenuState extends Equatable {
  const MenuState();
  @override
  List<Object?> get props => [];
}

class MenuInitial extends MenuState {}

class MenuLoading extends MenuState {}

class MenuLoaded extends MenuState {
  final MenuModel menu;
  const MenuLoaded(this.menu);

  @override
  List<Object?> get props => [menu];
}

class MenuError extends MenuState {
  final String message;
  const MenuError(this.message);

  @override
  List<Object?> get props => [message];
}

class MenuCubit extends Cubit<MenuState> {
  final MenuRepository _repository = MenuRepository();

  MenuCubit() : super(MenuInitial()) {
    loadMenu();
  }

  Future<void> loadMenu() async {
    emit(MenuLoading());
    try {
      final menu = await _repository.getActiveMenu();
      emit(MenuLoaded(menu));
    } catch (e) {
      emit(MenuError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateMenu(List<String> items, double price) async {
    emit(MenuLoading());
    try {
      final updated = await _repository.updateActiveMenu(items, price);
      emit(MenuLoaded(updated));
    } catch (e) {
      emit(MenuError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
