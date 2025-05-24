// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../../../dashboard/screens/Dashboard.dart';
import '../../../services/auth_service.dart';


class Loginscreen extends StatefulWidget {
  const Loginscreen({super.key});

  @override
  State<Loginscreen> createState() => _LoginscreenState();
}

class _LoginscreenState extends State<Loginscreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final AuthService _authService = AuthService();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // Enhanced validation
  String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Email format validation
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegExp.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  Future<void> _validateAndSubmit() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Call the API through the auth service
        final response = await _authService.login(
          emailController.text,
          passwordController.text,
        );

        // Set loading to false when API call completes
        setState(() {
          _isLoading = false;
        });

        if (response['success']) {
          // Get user role for welcome message
          final userRole = response['user']?['role'] ?? 'doctor';
          final roleDisplay = userRole == 'doctor' ? 'Doctor (Mobile Access)' 
                            : userRole == 'admin' ? 'Administrator' 
                            : 'Doctor & Admin';
          
          // Handle successful login
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome! Logged in as $roleDisplay'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Dashboard()),
          );
        } else {
          // Handle login failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Login failed'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle errors
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                SizedBox(
                  height: 100,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Blue "A"
                      Image.asset(
                        'assets/images/logo.png',
                        height: 80,
                        width: 80,
                      ),
                      // Orange circle (positioned slightly off to create the partial circle effect)
                      Positioned(
                        top: 5,
                        right: MediaQuery.of(context).size.width * 0.42,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // White card containing login form
                Container(
                  width: MediaQuery.of(context).size.width * 0.85,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF444444),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email field with validation
                        TextFormField(
                          controller: emailController,
                          validator: validateEmail,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            labelText: 'Email *',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[500]!),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Password field with validation and visibility toggle
                        TextFormField(
                          controller: passwordController,
                          validator: validatePassword,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                            labelText: 'Password *',
                            labelStyle: TextStyle(color: Colors.grey[700]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: Colors.grey[500]!),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Sign in button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4caf50), // Green color
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                              elevation: 0,
                            ),
                            onPressed: _isLoading ? null : _validateAndSubmit,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            )
                                : const Text(
                              'Sign in',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // Forgot Password link
                TextButton(
                  onPressed: () {
                    // Forgot password action
                  },
                  child: const Text(
                    'Forgot Password',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}