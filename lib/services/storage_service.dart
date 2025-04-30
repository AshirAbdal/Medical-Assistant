import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Keys for storing authentication data
  static const String userKey = 'user_data';
  static const String tokenKey = 'auth_token';
  static const String tokenExpiryKey = 'token_expiry';

  // Save user data to local storage
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userKey, jsonEncode(userData));
  }

  // Save auth token
  Future<bool> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(tokenKey, token);
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

  // Get token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
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
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}