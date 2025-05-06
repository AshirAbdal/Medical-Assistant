import 'package:flutter/material.dart';
import '/services/auth_service.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  String? _error;

  // Data will be loaded from API
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> patients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _authService.getPatients();

      if (response['success']) {
        setState(() {
          patients = List<Map<String, dynamic>>.from(response['patients'] ?? []);
          appointments = List<Map<String, dynamic>>.from(response['appointments'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load data';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // Continue with your existing UI code using the data from the API
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Rest of your UI code, using the API data
        ],
      ),
    );
  }
}