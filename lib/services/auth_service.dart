import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class AuthService {
  late String baseUrl;
  final StorageService _storageService = StorageService();

  AuthService() {
    // Set the appropriate URL based on platform and environment
    if (Platform.isAndroid) {
      // For Android emulator
      baseUrl = 'http://10.0.2.2/my_patients_api';
    } else if (Platform.isIOS) {
      // For iOS simulator
      baseUrl = 'http://localhost/my_patients_api';
    } else {
      // Default fallback
      baseUrl = 'http://localhost/my_patients_api';
    }

    // If testing on physical device, uncomment and use your computer's IP
    // baseUrl = 'http://192.168.1.100/my_patients_api';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login to: $baseUrl/api.php?url=login');
      print('With credentials - Email: $email, Password: $password');

      final response = await http.post(
        Uri.parse('$baseUrl/api.php?url=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Parse the response
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? responseData['error'] ?? 'An error occurred'
        };
      }
    } catch (e) {
      print('Login error: ${e.toString()}');
      // Handle any errors
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Method for making authenticated API requests
  Future<http.Response> authenticatedRequest(String endpoint, {Map<String, dynamic>? body}) async {
    final token = await _storageService.getToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    return http.post(
        Uri.parse('$baseUrl/api.php?url=$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token'
        },
        body: body != null ? jsonEncode(body) : null
    );
  }

  // Method to check if token is valid and not expired
  Future<bool> isTokenValid() async {
    try {
      final response = await authenticatedRequest('validate_token');
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Method to log out user
  Future<bool> logout() async {
    try {
      // Call logout API if your backend supports it
      await authenticatedRequest('logout');

      // Clear stored data
      await _storageService.clearAll();
      return true;
    } catch (e) {
      // Even if API call fails, clear local storage
      await _storageService.clearAll();
      return true;
    }
  }
}