import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

// Rate limiter implementation (keeping this as it's still useful)
class ApiRateLimiter {
  final Map<String, DateTime> _lastRequestTimes = {};
  final Map<String, int> _requestCounts = {};
  final Duration _timeWindow = Duration(minutes: 1);
  final Map<String, int> _limits = {
    'default': 60,      // 60 requests per minute by default
    'login': 5,         // 5 login attempts per minute
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
      // For Android emulator
      baseUrl = '$protocol://10.0.2.2/my_patients_api';
    } else if (Platform.isIOS) {
      // For iOS simulator
      baseUrl = '$protocol://localhost/my_patients_api';
    } else {
      // Default fallback
      baseUrl = '$protocol://localhost/my_patients_api';
    }

    // If testing on physical device, uncomment and use your computer's IP
    // baseUrl = '$protocol://192.168.1.100/my_patients_api';
  }

  // Enhanced login with input validation and rate limiting
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      // Check if currently locked out
      if (_loginLockoutUntil != null && DateTime.now().isBefore(_loginLockoutUntil!)) {
        final remainingSeconds = _loginLockoutUntil!.difference(DateTime.now()).inSeconds;
        return {
          'success': false,
          'message': 'Too many login attempts. Please try again in $remainingSeconds seconds.'
        };
      }

      // Reset lockout if it has expired
      if (_loginLockoutUntil != null && DateTime.now().isAfter(_loginLockoutUntil!)) {
        _loginAttempts = 0;
        _loginLockoutUntil = null;
      }

      // Check rate limiter
      if (!_rateLimiter.canMakeRequest('login')) {
        final waitTime = _rateLimiter.timeUntilReset('login');
        return {
          'success': false,
          'message': 'Rate limit exceeded. Please try again in $waitTime seconds.'
        };
      }

      // Input validation
      final sanitizedEmail = email.trim();

      if (sanitizedEmail.isEmpty) {
        return {
          'success': false,
          'message': 'Email is required'
        };
      }

      // Email format validation
      final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegExp.hasMatch(sanitizedEmail)) {
        return {
          'success': false,
          'message': 'Invalid email format'
        };
      }

      if (password.isEmpty) {
        return {
          'success': false,
          'message': 'Password is required'
        };
      }

      print('Attempting login to: $baseUrl/login');

      // Make login request with clean URL
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': sanitizedEmail,
          'password': password,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Reset login attempts on success
        _loginAttempts = 0;

        // Save user data
        if (responseData['user'] != null) {
          await _storageService.saveUserData(responseData['user']);
        }

        // Save PHP session ID
        if (responseData['sid'] != null) {
          await _storageService.saveSessionId(responseData['sid']);
        }

        return responseData;
      } else {
        // Increment failed login attempts
        _loginAttempts++;

        // Apply lockout if max attempts reached
        if (_loginAttempts >= _maxLoginAttempts) {
          _loginLockoutUntil = DateTime.now().add(Duration(seconds: _lockoutDurationSeconds));
          return {
            'success': false,
            'message': 'Too many failed login attempts. Please try again in $_lockoutDurationSeconds seconds.'
          };
        }

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

  // Validate session with the server
  Future<bool> validateSession() async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId == null) return false;

      final response = await http.get(
        Uri.parse('$baseUrl/validate_session'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        },
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['success'] ?? false;
      }

      return false;
    } catch (e) {
      print('Session validation error: ${e.toString()}');
      return false;
    }
  }

  // Fetch patients data
  Future<Map<String, dynamic>> getPatients() async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId == null) {
        return {
          'success': false,
          'message': 'Not authenticated'
        };
      }

      final response = await http.get(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch patients'
        };
      }
    } catch (e) {
      print('Get patients error: ${e.toString()}');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}'
      };
    }
  }

  // Log out user
  Future<bool> logout() async {
    try {
      final sessionId = await _storageService.getSessionId();

      if (sessionId != null) {
        // Call logout API with session ID
        await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Content-Type': 'application/json',
            'X-Session-ID': sessionId
          },
        );
      }

      // Clear stored data regardless of API call success
      await _storageService.clearAll();
      return true;
    } catch (e) {
      // Even if API call fails, clear local storage
      await _storageService.clearAll();
      return true;
    }
  }
}