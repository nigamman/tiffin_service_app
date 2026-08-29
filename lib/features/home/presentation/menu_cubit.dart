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
  final MenuModel lunchMenu;
  final MenuModel dinnerMenu;

  const MenuLoaded({
    required this.menu,
    required this.lunchMenu,
    required this.dinnerMenu,
  });

  @override
  List<Object?> get props => [menu, lunchMenu, dinnerMenu];
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
      final menus = await _repository.getActiveMenus();
      final lunch = menus.firstWhere((m) => m.slot == 'lunch', orElse: () => menus.first);
      final dinner = menus.firstWhere((m) => m.slot == 'dinner', orElse: () => menus.last);
      emit(MenuLoaded(menu: lunch, lunchMenu: lunch, dinnerMenu: dinner));
    } catch (e) {
      emit(MenuError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> updateMenu(List<String> items, double price, {String slot = 'lunch'}) async {
    emit(MenuLoading());
    try {
      await _repository.updateActiveMenu(items, price, slot);
      final menus = await _repository.getActiveMenus();
      final lunch = menus.firstWhere((m) => m.slot == 'lunch', orElse: () => menus.first);
      final dinner = menus.firstWhere((m) => m.slot == 'dinner', orElse: () => menus.last);
      emit(MenuLoaded(menu: lunch, lunchMenu: lunch, dinnerMenu: dinner));
    } catch (e) {
      emit(MenuError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}
