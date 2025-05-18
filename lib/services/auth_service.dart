// lib/services/auth_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

// Rate limiter implementation
class ApiRateLimiter {
  final Map<String, DateTime> _lastRequestTimes = {};
  final Map<String, int> _requestCounts = {};
  final Duration _timeWindow = Duration(minutes: 1);
  final Map<String, int> _limits = {
    'default': 60, // 60 requests per minute by default
    'login': 5, // 5 login attempts per minute
    'patient_create': 10, // 10 patient creation requests per minute
    // Add more endpoints as needed
  };

  bool canMakeRequest(String endpoint) {
    final now = DateTime.now();
    final key = endpoint.split('/').last;
    final limit = _limits[key] ?? _limits['default']!;

    // Reset counter if time window has passed
    if (_lastRequestTimes.containsKey(key) &&
        now.difference(_lastRequestTimes[key]!) > _timeWindow) {
      _requestCounts[key] = 0;
    }

    // Initialize if first request
    if (!_requestCounts.containsKey(key)) {
      _requestCounts[key] = 0;
      _lastRequestTimes[key] = now;
    }

    // Check if under limit
    if (_requestCounts[key]! < limit) {
      _requestCounts[key] = _requestCounts[key]! + 1;
      _lastRequestTimes[key] = now;
      return true;
    }

    return false;
  }

  int timeUntilReset(String endpoint) {
    final key = endpoint.split('/').last;
    if (!_lastRequestTimes.containsKey(key)) return 0;

    final elapsed = DateTime.now().difference(_lastRequestTimes[key]!);
    final remaining = _timeWindow.inSeconds - elapsed.inSeconds;
    return remaining > 0 ? remaining : 0;
  }
}

class AuthService {
  late String baseUrl;
  final StorageService _storageService = StorageService();
  final ApiRateLimiter _rateLimiter = ApiRateLimiter();
  final bool _isDevEnvironment = true; // Set to false for production

  // Login rate limiting
  int _loginAttempts = 0;
  DateTime? _loginLockoutUntil;
  final int _maxLoginAttempts = 5;
  final int _lockoutDurationSeconds = 300; // 5 minutes

  AuthService() {
    // For development, use HTTP. For production, use HTTPS
    final String protocol = _isDevEnvironment ? 'http' : 'https';

    if (Platform.isAndroid) {
      // For Android emulator, use 10.0.2.2 which maps to localhost on host
      baseUrl = '$protocol://10.0.2.2/my_patients_api';
    } else if (Platform.isIOS) {
      // For iOS simulator, use localhost
      baseUrl = '$protocol://localhost/my_patients_api';
    } else {
      // Default fallback
      baseUrl = '$protocol://localhost/my_patients_api';
    }

    // If testing on physical device, uncomment and use your computer's IP
    // baseUrl = '$protocol://192.168.1.100/my_patients_api';
  }

  // Method to ensure session is active after login
  Future<void> _ensureSessionActive(String sessionId) async {
    try {
      print("Ensuring session is active with ID: $sessionId");

      // First, try the validate_session endpoint
      var response = await http.get(
        Uri.parse('$baseUrl/validate_session'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
          'Cookie': 'PHPSESSID=$sessionId',
        },
      );

      print(
        "Session validation response: ${response.statusCode} - ${response.body}",
      );

      // If that fails, try a simple patient endpoint to "warm up" the session
      if (response.statusCode != 200) {
        response = await http.get(
          Uri.parse('$baseUrl/patients'),
          headers: {
            'Content-Type': 'application/json',
            'X-Session-ID': sessionId,
            'Cookie': 'PHPSESSID=$sessionId',
          },
        );

        print(
          "Warm-up patients request: ${response.statusCode} - ${response.body}",
        );
      }
    } catch (e) {
      print("Error ensuring session: $e");
    }
  }

  //IMPORTANT: Update in auth_service.dart

  // Enhanced login with input validation and rate limiting
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Check if currently locked out
      if (_loginLockoutUntil != null &&
          DateTime.now().isBefore(_loginLockoutUntil!)) {
        final remainingSeconds =
            _loginLockoutUntil!.difference(DateTime.now()).inSeconds;
        return {
          'success': false,
          'message':
              'Too many login attempts. Please try again in $remainingSeconds seconds.',
        };
      }

      // Reset lockout if it has expired
      if (_loginLockoutUntil != null &&
          DateTime.now().isAfter(_loginLockoutUntil!)) {
        _loginAttempts = 0;
        _loginLockoutUntil = null;
      }

      // Check rate limiter
      if (!_rateLimiter.canMakeRequest('login')) {
        final waitTime = _rateLimiter.timeUntilReset('login');
        return {
          'success': false,
          'message':
              'Rate limit exceeded. Please try again in $waitTime seconds.',
        };
      }

      // Input validation
      final sanitizedEmail = email.trim();

      if (sanitizedEmail.isEmpty) {
        return {'success': false, 'message': 'Email is required'};
      }

      // Email format validation
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(sanitizedEmail)) {
        return {'success': false, 'message': 'Invalid email format'};
      }

      if (password.isEmpty) {
        return {'success': false, 'message': 'Password is required'};
      }

      print('Attempting login to: $baseUrl/login');

      // Make login request with clean URL
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': sanitizedEmail, 'password': password}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Check for any cookies returned by the server
      if (response.headers.containsKey('set-cookie')) {
        print('Cookies returned by server: ${response.headers['set-cookie']}');
      }

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Reset login attempts on success
        _loginAttempts = 0;

        // Save user data
        if (responseData['user'] != null) {
          print('Saving user data: ${responseData['user']}');
          await _storageService.saveUserData(responseData['user']);

          // Save categories data if available
          if (responseData['user']['categories'] != null) {
            print(
              'Saving user categories: ${responseData['user']['categories']}',
            );
            List<dynamic> categories = responseData['user']['categories'];
            await _storageService.saveCategories(categories);
          } else {
            print('Warning: No categories found in user data');
          }
        } else {
          print('Warning: No user data found in response');
        }

        // Save PHP session ID and ensure it's active
        if (responseData['sid'] != null) {
          final sessionId = responseData['sid'];
          print('Saving PHP session ID: $sessionId');
          await _storageService.saveSessionId(sessionId);

          // Ensure the session is active
          await _ensureSessionActive(sessionId);
        } else {
          print('ERROR: No session ID (sid) found in login response!');
        }

        // Return the success response
        return {
          'success': true,
          'message': 'Login successful',
          'user': responseData['user'],
          'sid': responseData['sid'],
        };
      } else {
        // Increment failed login attempts
        _loginAttempts++;
        print('Login failed. Attempt #$_loginAttempts of $_maxLoginAttempts');

        // Apply lockout if max attempts reached
        if (_loginAttempts >= _maxLoginAttempts) {
          _loginLockoutUntil = DateTime.now().add(
            Duration(seconds: _lockoutDurationSeconds),
          );
          print(
            'Account locked for $_lockoutDurationSeconds seconds due to too many failed attempts',
          );
          return {
            'success': false,
            'message':
                'Too many failed login attempts. Please try again in $_lockoutDurationSeconds seconds.',
          };
        }

        return {
          'success': false,
          'message': responseData['message'] ?? 'An error occurred',
        };
      }
    } catch (e) {
      print('Login error: ${e.toString()}');
      // Handle any errors
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Test session after login
  Future<bool> testSessionAfterLogin(String sessionId) async {
    try {
      print("Testing session with ID: $sessionId");

      final response = await http.get(
        Uri.parse('$baseUrl/validate_session'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
          'Cookie':
              'PHPSESSID=$sessionId', // Try adding the session as a cookie too
        },
      );

      print("Session test status: ${response.statusCode}");
      print("Session test body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }

      return false;
    } catch (e) {
      print("Session test error: $e");
      return false;
    }
  }

  Future<bool> validateSession() async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId == null) {
        print("validateSession: No session ID found");
        return false;
      }

      print("validateSession: Testing with session ID: $sessionId");

      // Create a Map of headers including both the session ID header and cookies
      final headers = {
        'Content-Type': 'application/json',
        'X-Session-ID': sessionId,
        'Cookie': 'PHPSESSID=$sessionId',
      };

      final response = await http.get(
        Uri.parse('$baseUrl/validate_session'),
        headers: headers,
      );

      print("validateSession status: ${response.statusCode}");
      print("validateSession body: ${response.body}");

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Save updated user data if available
        if (responseData['success'] && responseData['user'] != null) {
          await _storageService.saveUserData(responseData['user']);

          // Save categories data if available
          if (responseData['user']['categories'] != null) {
            List<dynamic> categories = responseData['user']['categories'];
            await _storageService.saveCategories(categories);
          }
        }

        return responseData['success'] ?? false;
      }

      return false;
    } catch (e) {
      print('Session validation error: ${e.toString()}');
      return false;
    }
  }

  // Fetch patients data
  Future<Map<String, dynamic>> getPatients({int? categoryId}) async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      // Add categoryId as query parameter if provided
      String url = '$baseUrl/patients';
      if (categoryId != null) {
        url += '?category_id=$categoryId';
      }

      print("getPatients: Requesting from $url with session ID: $sessionId");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
          'Cookie': 'PHPSESSID=$sessionId', // Add cookie for PHP sessions
        },
      );

      print("getPatients status: ${response.statusCode}");
      print("getPatients body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch patients'};
      }
    } catch (e) {
      print('Get patients error: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Get all categories
  Future<Map<String, dynamic>> getCategories() async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId == null) {
        return {'success': false, 'message': 'Not authenticated'};
      }

      print("getCategories: Requesting with session ID: $sessionId");

      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
          'Cookie': 'PHPSESSID=$sessionId', // Add cookie for PHP sessions
        },
      );

      print("getCategories status: ${response.statusCode}");
      print("getCategories body: ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'success': false, 'message': 'Failed to fetch categories'};
      }
    } catch (e) {
      print('Get categories error: ${e.toString()}');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // Log out user
  Future<bool> logout() async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId != null) {
        print("logout: Requesting with session ID: $sessionId");

        // Call logout API with session ID
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'X-Session-ID': sessionId,
            'Cookie': 'PHPSESSID=$sessionId', // Add cookie for PHP sessions
          },
        );
      }

      // Clear stored data regardless of API call success
      await _storageService.clearAll();
      return true;
    } catch (e) {
      print('Logout error: ${e.toString()}');
      // Even if API call fails, clear local storage
      await _storageService.clearAll();
      return true;
    }
  }

  // Debug method to get raw API response
  Future<Map<String, dynamic>> debugApiCall(String endpoint) async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId == null) {
        return {'error': 'No session ID found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId,
          'Cookie': 'PHPSESSID=$sessionId',
        },
      );

      return {
        'status': response.statusCode,
        'body': response.body,
        'headers': response.headers,
        'sessionId': sessionId,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}
