import 'package:flutter/material.dart';
import 'features/splash/splash_screen.dart';

void main() {
  // Ensure Flutter is properly initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Run the app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Patients',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4caf50)),
        useMaterial3: true,
      ),
      // Start with the splash screen which will handle authentication check
      home: const SplashScreen(),
    );
  }
}