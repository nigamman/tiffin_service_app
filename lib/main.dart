import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/presentation/auth_cubit.dart';
import 'features/home/presentation/menu_cubit.dart';
import 'features/orders/presentation/orders_cubit.dart';
import 'features/home/presentation/main_layout.dart';
import 'features/onboarding/presentation/welcome_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/services/firebase_service.dart';
import 'firebase_options.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Seed default data if Firestore is empty
  await FirebaseService.instance.seedIfEmpty();
  
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
        title: "Atithi Bhoj Tiffin Service",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const WelcomeScreen(),
      ),
    );
  }
}
