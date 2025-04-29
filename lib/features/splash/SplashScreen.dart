import 'package:flutter/material.dart';
import '/features/auth/screens/LoginScreen.dart';
import '/dashboard/screens/Dashboard.dart';
import '/services/storage_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // Add a slight delay to show the splash screen
    await Future.delayed(const Duration(seconds: 2));

    // Check if the user is logged in
    final bool isLoggedIn = await _storageService.isLoggedIn();

    if (mounted) {
      // Navigate to the appropriate screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => isLoggedIn ? const Dashboard() : const Loginscreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo
            SizedBox(
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Logo image
                  Image.asset(
                    'assets/images/logo.png',
                    height: 100,
                    width: 100,
                  ),
                  // Orange circle (positioned slightly off to create the partial circle effect)
                  Positioned(
                    top: 10,
                    right: MediaQuery.of(context).size.width * 0.43,
                    child: Container(
                      width: 35,
                      height: 35,
                      decoration: const BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // App name
            const Text(
              'My Patients',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF4caf50),
              ),
            ),

            const SizedBox(height: 50),

            // Loading spinner
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4caf50)),
            ),
          ],
        ),
      ),
    );
  }
}