import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Keys for storing authentication data
  static const String userKey = 'user_data';
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String tokenExpiryKey = 'token_expiry';

  // Use secure storage for sensitive information
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save user data to local storage
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userKey, jsonEncode(userData));
  }

  // Save auth token securely
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: tokenKey, value: token);
  }

  // Save refresh token securely
  Future<void> saveRefreshToken(String token) async {
    await _secureStorage.write(key: refreshTokenKey, value: token);
  }

  // Save token expiry timestamp
  Future<bool> saveTokenExpiry(int expiryTimestamp) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setInt(tokenExpiryKey, expiryTimestamp);
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(userKey);

    if (userStr != null) {
      return jsonDecode(userStr) as Map<String, dynamic>;
    }

    return null;
  }

  // Get token securely
  Future<String?> getToken() async {
    return await _secureStorage.read(key: tokenKey);
  }

  // Get refresh token securely
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: refreshTokenKey);
  }

  // Get token expiry
  Future<int?> getTokenExpiry() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(tokenExpiryKey);
  }

  // Check if user is logged in and token is valid
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    final expiry = await getTokenExpiry();

    if (token == null) return false;

    // Check if token has expired
    if (expiry != null) {
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return expiry > now;
    }

    return token != null;
  }

  // Clear all data (for logout)
  Future<bool> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      print('Error clearing storage: ${e.toString()}');
      return false;
    }
  }
}