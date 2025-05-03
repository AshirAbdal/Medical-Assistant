import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import '../services/storage_service.dart';

// Rate limiter implementation
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
  final Dio _dio = Dio();
  final bool _isDevEnvironment = true; // Set to false for production

  // Login rate limiting
  int _loginAttempts = 0;
  DateTime? _loginLockoutUntil;
  final int _maxLoginAttempts = 5;
  final int _lockoutDurationSeconds = 300; // 5 minutes

  // CSRF Protection
  String? _csrfToken;

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

    // Initialize CSRF protection
    initCsrfProtection();
  }

  // Initialize CSRF protection
  Future<void> initCsrfProtection() async {
    _csrfToken = await getCsrfToken();
  }

  // Get CSRF token from server
  Future<String?> getCsrfToken() async {
    try {
      // In development, we might not have a CSRF endpoint yet, so return a dummy token
      if (_isDevEnvironment) {
        // For development, use a fixed token (remove in production!)
        return 'dev_csrf_token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api.php?url=csrf_token'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['csrf_token'] != null) {
          return responseData['csrf_token'];
        }
      }

      return null;
    } catch (e) {
      print('CSRF token error: ${e.toString()}');
      return null;
    }
  }

  // Enhanced login with input validation, rate limiting, and HTTPS
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

      print('Attempting login to: $baseUrl/api.php?url=login');

      // Make login request
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?url=login'),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': _csrfToken ?? ''
        },
        body: jsonEncode({
          'email': sanitizedEmail,
          'password': password,
          'csrf_token': _csrfToken
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        // Reset login attempts on success
        _loginAttempts = 0;

        // Save user data and token
        if (responseData['user'] != null) {
          await _storageService.saveUserData(responseData['user']);
        }

        // Save token information
        if (responseData['token'] != null) {
          await _storageService.saveToken(responseData['token']);
        }

        // Save refresh token if present
        if (responseData['refresh_token'] != null) {
          await _storageService.saveRefreshToken(responseData['refresh_token']);
        }

        // Save token expiry if exists
        if (responseData['expires_at'] != null) {
          await _storageService.saveTokenExpiry(responseData['expires_at']);
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

  // Token refresh mechanism
  Future<String?> getValidToken() async {
    final token = await _storageService.getToken();
    final expiry = await _storageService.getTokenExpiry();

    if (token == null) return null;

    // Check if token is about to expire (within 5 minutes)
    if (expiry != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if (expiry - now < 300) { // 300 seconds = 5 minutes
        // Token is about to expire, refresh it
        return refreshToken();
      }
    }

    return token;
  }

  Future<String?> refreshToken() async {
    try {
      if (!_rateLimiter.canMakeRequest('refresh_token')) {
        final waitTime = _rateLimiter.timeUntilReset('refresh_token');
        print('Token refresh rate limited. Try again in $waitTime seconds.');
        return null;
      }

      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/api.php?url=refresh_token'),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-TOKEN': _csrfToken ?? ''
        },
        body: jsonEncode({
          'refresh_token': refreshToken,
          'csrf_token': _csrfToken
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success']) {
          // Save new tokens
          await _storageService.saveToken(responseData['token']);
          if (responseData['refresh_token'] != null) {
            await _storageService.saveRefreshToken(responseData['refresh_token']);
          }
          if (responseData['expires_at'] != null) {
            await _storageService.saveTokenExpiry(responseData['expires_at']);
          }

          return responseData['token'];
        }
      }

      return null;
    } catch (e) {
      print('Token refresh error: ${e.toString()}');
      return null;
    }
  }

  // Enhanced authenticated request with CSRF, rate limiting, and token refresh
  Future<http.Response> authenticatedRequest(String endpoint, {Map<String, dynamic>? body}) async {
    // Check rate limiter
    if (!_rateLimiter.canMakeRequest(endpoint)) {
      final waitTime = _rateLimiter.timeUntilReset(endpoint);
      throw Exception('Rate limit exceeded. Please try again in $waitTime seconds.');
    }

    // Get valid token (refreshes if needed)
    final token = await getValidToken();

    if (token == null) {
      throw Exception('Not authenticated');
    }

    // Create request body with CSRF token
    final Map<String, dynamic> requestBody = {};
    if (body != null) {
      requestBody.addAll(body);
    }
    if (_csrfToken != null) {
      requestBody['csrf_token'] = _csrfToken;
    }

    // Make authenticated request
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api.php?url=$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'X-CSRF-TOKEN': _csrfToken ?? ''
        },
        body: jsonEncode(requestBody),
      );

      // Check if token expired (401 status)
      if (response.statusCode == 401) {
        // Try to refresh token and retry request once
        final newToken = await refreshToken();
        if (newToken != null) {
          return await http.post(
            Uri.parse('$baseUrl/api.php?url=$endpoint'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $newToken',
              'X-CSRF-TOKEN': _csrfToken ?? ''
            },
            body: jsonEncode(requestBody),
          );
        }
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Check if token is valid and not expired
  Future<bool> isTokenValid() async {
    try {
      final response = await authenticatedRequest('validate_token');
      final responseData = jsonDecode(response.body);
      return responseData['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Log out user
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