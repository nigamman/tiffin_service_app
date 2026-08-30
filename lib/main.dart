import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  
  // One-time clear flag for fresh testing.
  // Set to true to clear, then set to false.
  const bool shouldClearData = true;
  if (shouldClearData) {
    try {
      final firestore = FirebaseFirestore.instance;
      // Delete orders
      final ordersSnap = await firestore.collection('orders').get();
      for (final doc in ordersSnap.docs) {
        await doc.reference.delete();
      }
      // Delete users
      final usersSnap = await firestore.collection('users').get();
      for (final doc in usersSnap.docs) {
        await doc.reference.delete();
      }
      // Clear SharedPreferences local auth cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print("--- CLEARED ALL USER AND TIFFIN DATA SUCCESSFULLY ---");
    } catch (e) {
      print("Error clearing data: $e");
    }
  }
  
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
