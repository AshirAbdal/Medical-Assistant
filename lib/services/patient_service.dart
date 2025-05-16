// lib/services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';
import '../models/patient.dart';
import '../models/category.dart';

class PatientService {
  final String baseUrl;
  final StorageService _storageService = StorageService();

  PatientService({required this.baseUrl});

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

      // Make API request with session ID in header
      final response = await http.get(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            'X-Session-ID': sessionId
          }
      );

      print("Patient API response status: ${response.statusCode}");
      print("Patient API response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          if (data['patients'] == null) {
            print("Warning: 'patients' field is null in response");
            return [];
          }

          final patientList = (data['patients'] as List)
              .map((patientJson) => Patient.fromJson(patientJson))
              .toList();

          print("Parsed ${patientList.length} patients from API response");
          return patientList;
        } else {
          throw Exception(data['message'] ?? 'Failed to load patients');
        }
      } else {
        throw Exception('Failed to load patients: Status ${response.statusCode}');
      }
    } catch (e) {
      print("Error in getMyPatients: ${e.toString()}");
      throw Exception('Error loading patients: ${e.toString()}');
    }
  }

  Future<List<Category>> getCategories() async {
    // Get session ID from storage
    final sessionId = await _storageService.getSessionId();

    if (sessionId == null) {
      throw Exception('Not authenticated');
    }

    // Make API request with session ID in header
    final response = await http.get(
        Uri.parse('$baseUrl/categories'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        }
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return (data['categories'] as List)
            .map((categoryJson) => Category.fromJson(categoryJson))
            .toList();
      } else {
        throw Exception(data['message'] ?? 'Failed to load categories');
      }
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<Patient> addPatient(Map<String, dynamic> patientData) async {
    // Get session ID from storage
    final sessionId = await _storageService.getSessionId();

    if (sessionId == null) {
      throw Exception('Not authenticated');
    }

    // Make API request with session ID in header
    final response = await http.post(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        },
        body: jsonEncode(patientData)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return Patient.fromJson(data['patient']);
      } else {
        throw Exception(data['message'] ?? 'Failed to add patient');
      }
    } else {
      throw Exception('Failed to add patient');
    }
  }

  Future<Patient> updatePatient(int patientId, Map<String, dynamic> patientData) async {
    // Get session ID from storage
    final sessionId = await _storageService.getSessionId();

    if (sessionId == null) {
      throw Exception('Not authenticated');
    }

    // Make API request with session ID in header
    final response = await http.put(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        },
        body: jsonEncode(patientData)
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return Patient.fromJson(data['patient']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update patient');
      }
    } else {
      throw Exception('Failed to update patient');
    }
  }

  Future<bool> deletePatient(int patientId) async {
    // Get session ID from storage
    final sessionId = await _storageService.getSessionId();

    if (sessionId == null) {
      throw Exception('Not authenticated');
    }

    // Make API request with session ID in header
    final response = await http.delete(
        Uri.parse('$baseUrl/patients/$patientId'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        }
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] ?? false;
    } else {
      throw Exception('Failed to delete patient');
    }
  }
}