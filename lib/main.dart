import 'package:flutter/material.dart';
import 'features/splash/SplashScreen.dart';

void main() {
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
      home: const SplashScreen(),
    );
  }
}