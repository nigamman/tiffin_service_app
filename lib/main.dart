import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/home/presentation/menu_cubit.dart';
import 'features/orders/presentation/orders_cubit.dart';
import 'features/home/presentation/main_layout.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const TiffinServiceApp());
}

class TiffinServiceApp extends StatelessWidget {
  const TiffinServiceApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => AuthCubit(),
        ),
        BlocProvider<MenuCubit>(
          create: (context) => MenuCubit(),
        ),
        BlocProvider<OrdersCubit>(
          create: (context) => OrdersCubit(),
        ),
      ],
      child: MaterialApp(
        title: "Kanpur's First Tiffin Service",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainLayout(),
      ),
    );
  }
}
