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
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving user data: ${jsonEncode(userData)}');
      return prefs.setString(userKey, jsonEncode(userData));
    } catch (e) {
      print('Error saving user data: $e');
      return false;
    }
  }

  // Save PHP session ID securely
  Future<void> saveSessionId(String sessionId) async {
    try {
      await _secureStorage.write(key: sessionIdKey, value: sessionId);
      // For debugging
      print('Session ID saved: $sessionId');
      
      // Verify it was saved correctly
      final verificationRead = await _secureStorage.read(key: sessionIdKey);
      print('Session ID verification read: $verificationRead');
      
      if (verificationRead != sessionId) {
        print('WARNING: Session ID verification failed! Saved and read values don\'t match!');
      }
    } catch (e) {
      print('Error saving session ID: $e');
    }
  }

  // Save doctor categories
  Future<bool> saveCategories(List<dynamic> categories) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving categories: ${jsonEncode(categories)}');
      return prefs.setString(categoriesKey, jsonEncode(categories));
    } catch (e) {
      print('Error saving categories: $e');
      return false;
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(userKey);

      if (userStr != null) {
        final userData = jsonDecode(userStr) as Map<String, dynamic>;
        print('Retrieved user data: $userData');
        return userData;
      }
      
      print('No user data found in storage');
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }

  // Get session ID securely
  Future<String?> getSessionId() async {
    try {
      final sid = await _secureStorage.read(key: sessionIdKey);
      // For debugging
      print('Retrieved session ID: $sid');
      return sid;
    } catch (e) {
      print('Error getting session ID: $e');
      return null;
    }
  }
  
  // Get doctor categories as raw maps
  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final categoriesStr = prefs.getString(categoriesKey);

      if (categoriesStr != null) {
        List<dynamic> data = jsonDecode(categoriesStr);
        final categories = data.map((e) => Map<String, dynamic>.from(e)).toList();
        print('Retrieved categories: $categories');
        return categories;
      }
      
      print('No categories found in storage');
      return [];
    } catch (e) {
      print('Error getting categories: $e');
      return [];
    }
  }

  // Get doctor categories as Category objects
  Future<List<Category>> getCategoryObjects() async {
    try {
      final categories = await getCategories();
      return categories.map((e) => Category.fromJson(e)).toList();
    } catch (e) {
      print('Error converting categories to objects: $e');
      return [];
    }
  }

  // Get doctor category IDs
  Future<List<int>> getDoctorCategoryIds() async {
    try {
      final categories = await getCategories();
      return categories.map((c) => c['id'] as int).toList();
    } catch (e) {
      print('Error getting category IDs: $e');
      return [];
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final sessionId = await getSessionId();
      final userData = await getUserData();
      return sessionId != null && userData != null;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Clear all data (for logout)
  Future<bool> clearAll() async {
    try {
      print('Clearing all storage data');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await _secureStorage.deleteAll();
      print('Storage cleared successfully');
      return true;
    } catch (e) {
      print('Error clearing storage: $e');
      return false;
    }
  }
}