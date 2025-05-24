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
  static const String userRoleKey = 'user_role';
  static const String userPermissionsKey = 'user_permissions';

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

  // Save user role
  Future<bool> saveUserRole(String role) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving user role: $role');
      return prefs.setString(userRoleKey, role);
    } catch (e) {
      print('Error saving user role: $e');
      return false;
    }
  }
  
  // Save user permissions
  Future<bool> saveUserPermissions(Map<String, dynamic> permissions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      print('Saving user permissions: ${jsonEncode(permissions)}');
      return prefs.setString(userPermissionsKey, jsonEncode(permissions));
    } catch (e) {
      print('Error saving user permissions: $e');
      return false;
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
  
  // Get user role
  Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString(userRoleKey);
      print('Retrieved user role: $role');
      return role;
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }
  
  // Get user permissions
  Future<Map<String, dynamic>?> getUserPermissions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final permissionsStr = prefs.getString(userPermissionsKey);
      
      if (permissionsStr != null) {
        final permissions = jsonDecode(permissionsStr) as Map<String, dynamic>;
        print('Retrieved user permissions: $permissions');
        return permissions;
      }
      
      print('No user permissions found in storage');
      return null;
    } catch (e) {
      print('Error getting user permissions: $e');
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

  // Check if user is doctor only (restricted access)
  Future<bool> isDoctorOnly() async {
    final role = await getUserRole();
    return role == 'doctor';
  }
  
  // Check if user has admin access
  Future<bool> hasAdminAccess() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'doctor_admin';
  }
  
  // Check if user can access web
  Future<bool> canAccessWeb() async {
    final role = await getUserRole();
    return role == 'admin' || role == 'doctor_admin';
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final sessionId = await getSessionId();
      final userData = await getUserData();
      final userRole = await getUserRole();
      return sessionId != null && userData != null && userRole != null;
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
  
  // Get user display info (name and role)
  Future<Map<String, String>> getUserDisplayInfo() async {
    try {
      final userData = await getUserData();
      final role = await getUserRole();
      
      if (userData != null) {
        return {
          'name': userData['name'] ?? 'User',
          'email': userData['email'] ?? '',
          'role': _formatRole(role ?? 'doctor'),
        };
      }
      
      return {'name': 'User', 'email': '', 'role': 'Unknown'};
    } catch (e) {
      print('Error getting user display info: $e');
      return {'name': 'User', 'email': '', 'role': 'Unknown'};
    }
  }
  
  // Helper method to format role for display
  String _formatRole(String role) {
    switch (role) {
      case 'doctor':
        return 'Doctor';
      case 'admin':
        return 'Administrator';
      case 'doctor_admin':
        return 'Doctor & Admin';
      default:
        return 'Unknown';
    }
  }
}