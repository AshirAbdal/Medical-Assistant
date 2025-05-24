// lib/features/splash/splash_screen.dart
import 'package:flutter/material.dart';
import '../auth/screens/login_screen.dart';
import '/dashboard/screens/Dashboard.dart';
import '/services/storage_service.dart';
import '/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Add a slight delay to show the splash screen
      await Future.delayed(const Duration(seconds: 2));

      // First check if there's a stored session
      final sessionId = await _storageService.getSessionId();
      print("SplashScreen: Retrieved session ID: $sessionId");
      
      bool isLoggedIn = false;
      
      if (sessionId != null) {
        // If we have a session ID, validate it with the server
        print("SplashScreen: Validating session with server");
        isLoggedIn = await _authService.validateSession();
        print("SplashScreen: Session validation result: $isLoggedIn");
      } else {
        print("SplashScreen: No session ID found");
      }

      // If we're still mounted, navigate to the appropriate screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => isLoggedIn ? const Dashboard() : const Loginscreen(),
          ),
        );
      }
    } catch (e) {
      print("Error in SplashScreen: ${e.toString()}");
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error connecting to server. Please try again.";
        });
        
        // Add a retry button if there's an error
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const Loginscreen()),
          );
        }
      }
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

            // Loading spinner or error message
            if (_isLoading)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4caf50)),
              )
            else if (_errorMessage != null)
              Column(
                children: [
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      _checkLoginStatus();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4caf50),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}