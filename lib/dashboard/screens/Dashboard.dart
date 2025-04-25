import 'package:flutter/material.dart';
import '../../features/auth/screens/LoginScreen.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Loginscreen()),
          ),
        ),
      ),
      body: const Center(
        child: Text('Welcome to Dashboard!'),
      ),
    );
  }
}