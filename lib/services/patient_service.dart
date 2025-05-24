// lib/services/patient_service.dart
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/patient.dart';
import '../models/category.dart';

class PatientService {
  late String baseUrl;
  final StorageService _storageService = StorageService();
  final bool _isDevEnvironment = true; // Set to false for production

  PatientService() {
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

  // Helper method to get headers with app type identification
  Map<String, String> _getHeaders({String? sessionId}) {
    final headers = {
      'Content-Type': 'application/json',
      'X-App-Type': 'mobile', // Identify this as mobile app
    };
    
    if (sessionId != null) {
      headers['X-Session-ID'] = sessionId;
      headers['Cookie'] = 'PHPSESSID=$sessionId';
    }
    
    return headers;
  }

  Future<List<Patient>> getMyPatients({int? categoryId}) async {
    try {
      // Get session ID from storage
      final sessionId = await _storageService.getSessionId();
      print("Getting patients with sessionId: $sessionId");

      if (sessionId == null) {
        throw Exception('Not authenticated');
      }

      // Add categoryId to query if provided
      String url = '$baseUrl/patients';
      if (categoryId != null) {
        url += '?category_id=$categoryId';
      }

      print("Fetching patients from: $url");

      // Make API request with session ID in both header and cookie
      final response = await http.get(
        Uri.parse(url),
        headers: _getHeaders(sessionId: sessionId)
      );

      print("Patient API response status: ${response.statusCode}");
      print("Patient API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          // Check if the data contains patients
          if (data['patients'] == null) {
            print("Warning: 'patients' field is null in response");
            return [];
          }

          // Parse the list of patients
          final List<dynamic> patientsJson = data['patients'];
          final List<Patient> patientsList = [];
          
          for (var patientJson in patientsJson) {
            try {
              final patient = Patient.fromJson(patientJson);
              patientsList.add(patient);
            } catch (e) {
              print("Error parsing patient data: $e");
              print("Problem JSON: $patientJson");
              // Continue with next patient instead of failing completely
            }
          }
          
          print("Successfully parsed ${patientsList.length} patients");
          return patientsList;
        } else {
          // API returned success: false
          throw Exception(data['message'] ?? 'Failed to load patients');
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        // Handle access denied
        throw Exception('Access denied. You do not have permission to access this resource.');
      } else {
        // Handle other HTTP errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in getMyPatients: ${e.toString()}");
      // Re-throw to let UI handle it
      throw Exception('Error loading patients: ${e.toString()}');
    }
  }

  Future<List<Category>> getCategories() async {
    try {
      // Get session ID from storage
      final sessionId = await _storageService.getSessionId();
      print("Getting categories with sessionId: $sessionId");

      if (sessionId == null) {
        throw Exception('Not authenticated');
      }

      // Make API request with session ID in both header and cookie
      final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: _getHeaders(sessionId: sessionId)
      );

      print("Categories API response status: ${response.statusCode}");
      print("Categories API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          // Check if the data contains categories
          if (data['categories'] == null) {
            print("Warning: 'categories' field is null in response");
            return [];
          }

          // Parse the list of categories
          final List<dynamic> categoriesJson = data['categories'];
          final List<Category> categoriesList = [];
          
          for (var categoryJson in categoriesJson) {
            try {
              final category = Category.fromJson(categoryJson);
              categoriesList.add(category);
            } catch (e) {
              print("Error parsing category data: $e");
              print("Problem JSON: $categoryJson");
              // Continue with next category instead of failing completely
            }
          }
          
          print("Successfully parsed ${categoriesList.length} categories");
          return categoriesList;
        } else {
          // API returned success: false
          throw Exception(data['message'] ?? 'Failed to load categories');
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        // Handle access denied
        throw Exception('Access denied. You do not have permission to access this resource.');
      } else {
        // Handle other HTTP errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in getCategories: ${e.toString()}");
      // Re-throw to let UI handle it
      throw Exception('Error loading categories: ${e.toString()}');
    }
  }

  Future<Patient> addPatient(Map<String, dynamic> patientData) async {
    try {
      // Get session ID from storage
      final sessionId = await _storageService.getSessionId();
      print("Adding patient with sessionId: $sessionId");

      if (sessionId == null) {
        throw Exception('Not authenticated');
      }

      // Make API request with session ID in both header and cookie
      final response = await http.post(
        Uri.parse('$baseUrl/patients'),
        headers: _getHeaders(sessionId: sessionId),
        body: jsonEncode(patientData)
      );

      print("Add patient API response status: ${response.statusCode}");
      print("Add patient API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          // Check if the data contains the new patient
          if (data['patient'] == null) {
            throw Exception('No patient data returned from API');
          }

          // Parse the new patient
          return Patient.fromJson(data['patient']);
        } else {
          // API returned success: false
          throw Exception(data['message'] ?? 'Failed to add patient');
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        // Handle access denied
        throw Exception('Access denied. You do not have permission to add patients.');
      } else {
        // Handle other HTTP errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in addPatient: ${e.toString()}");
      // Re-throw to let UI handle it
      throw Exception('Error adding patient: ${e.toString()}');
    }
  }

  Future<Patient> updatePatient(int patientId, Map<String, dynamic> patientData) async {
    try {
      // Get session ID from storage
      final sessionId = await _storageService.getSessionId();
      print("Updating patient with sessionId: $sessionId");

      if (sessionId == null) {
        throw Exception('Not authenticated');
      }

      // Make API request with session ID in both header and cookie
      final response = await http.put(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: _getHeaders(sessionId: sessionId),
        body: jsonEncode(patientData)
      );

      print("Update patient API response status: ${response.statusCode}");
      print("Update patient API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success']) {
          // Check if the data contains the updated patient
          if (data['patient'] == null) {
            throw Exception('No patient data returned from API');
          }

          // Parse the updated patient
          return Patient.fromJson(data['patient']);
        } else {
          // API returned success: false
          throw Exception(data['message'] ?? 'Failed to update patient');
        }
      } else if (response.statusCode == 401) {
        // Handle authentication error
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        // Handle access denied
        throw Exception('Access denied. You do not have permission to update patients.');
      } else {
        // Handle other HTTP errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in updatePatient: ${e.toString()}");
      // Re-throw to let UI handle it
      throw Exception('Error updating patient: ${e.toString()}');
    }
  }

  Future<bool> deletePatient(int patientId) async {
    try {
      // Get session ID from storage
      final sessionId = await _storageService.getSessionId();
      print("Deleting patient with sessionId: $sessionId");

      if (sessionId == null) {
        throw Exception('Not authenticated');
      }

      // Make API request with session ID in both header and cookie
      final response = await http.delete(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: _getHeaders(sessionId: sessionId)
      );

      print("Delete patient API response status: ${response.statusCode}");
      print("Delete patient API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      } else if (response.statusCode == 401) {
        // Handle authentication error
        throw Exception('Authentication failed. Please login again.');
      } else if (response.statusCode == 403) {
        // Handle access denied
        throw Exception('Access denied. You do not have permission to delete patients.');
      } else {
        // Handle other HTTP errors
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print("Error in deletePatient: ${e.toString()}");
      // Re-throw to let UI handle it
      throw Exception('Error deleting patient: ${e.toString()}');
    }
  }
  
  // Helper method to test the API connection directly (can be used for debugging)
  Future<Map<String, dynamic>> testApiConnection() async {
    try {
      final sessionId = await _storageService.getSessionId();
      
      if (sessionId == null) {
        return {'success': false, 'message': 'No session ID found'};
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/patients'),
        headers: _getHeaders(sessionId: sessionId)
      );
      
      return {
        'success': true,
        'status': response.statusCode,
        'body': response.body,
        'sessionId': sessionId
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }
}