import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  // Keys for storing data
  static const String userKey = 'user_data';
  static const String sessionIdKey = 'session_id'; // New key for PHP session ID

  // Use secure storage for sensitive information
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Save user data to local storage
  Future<bool> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(userKey, jsonEncode(userData));
  }

  // Save PHP session ID securely
  Future<void> saveSessionId(String sessionId) async {
    await _secureStorage.write(key: sessionIdKey, value: sessionId);
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

  // Get session ID securely
  Future<String?> getSessionId() async {
    return await _secureStorage.read(key: sessionIdKey);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final sessionId = await getSessionId();
    return sessionId != null;
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