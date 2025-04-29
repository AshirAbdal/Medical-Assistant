import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

class AuthService {
  late String apiUrl;

  AuthService() {
    // Set the appropriate URL based on platform and environment
    if (Platform.isAndroid) {
      // For Android emulator
      apiUrl = 'http://10.0.2.2/my_patients_api/login_api.php';
    } else if (Platform.isIOS) {
      // For iOS simulator
      apiUrl = 'http://localhost/my_patients_api/login_api.php';
    } else {
      // Default fallback
      apiUrl = 'http://localhost/my_patients_api/login_api.php';
    }

    // If testing on physical device, uncomment and use your computer's IP
    // apiUrl = 'http://192.168.1.100/my_patients_api/login_api.php';
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login to: $apiUrl');
      print('With credentials - Email: $email, Password: $password');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action':'login',
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
          'message': responseData['message'] ?? 'An error occurred'
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
}