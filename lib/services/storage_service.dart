import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // Keys
  static const String userKey = 'user_data';
  static const String tokenKey = 'auth_token';

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

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Clear all data (for logout)
  Future<bool> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.clear();
  }
}