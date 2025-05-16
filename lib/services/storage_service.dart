// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/category.dart';

class StorageService {
  // Keys for storing data
  static const String userKey = 'user_data';
  static const String sessionIdKey = 'session_id';
  static const String categoriesKey = 'doctor_categories';

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
    // For debugging
    print('Session ID saved: $sessionId');
  }

  // Save doctor categories
  Future<bool> saveCategories(List<dynamic> categories) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString(categoriesKey, jsonEncode(categories));
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
    final sid = await _secureStorage.read(key: sessionIdKey);
    // For debugging
    print('Retrieved session ID: $sid');
    return sid;
  }
  // Get doctor categories as raw maps
  Future<List<Map<String, dynamic>>> getCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesStr = prefs.getString(categoriesKey);

    if (categoriesStr != null) {
      List<dynamic> data = jsonDecode(categoriesStr);
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    return [];
  }

  // Get doctor categories as Category objects
  Future<List<Category>> getCategoryObjects() async {
    final categories = await getCategories();
    return categories.map((e) => Category.fromJson(e)).toList();
  }

  // Get doctor category IDs
  Future<List<int>> getDoctorCategoryIds() async {
    final categories = await getCategories();
    return categories.map((c) => c['id'] as int).toList();
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