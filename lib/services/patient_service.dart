// lib/services/patient_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../services/storage_service.dart';

class PatientService {
  final String baseUrl;
  final StorageService _storageService = StorageService();

  PatientService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> getMyPatients() async {
    // Get session ID from storage
    final sessionId = await _storageService.getSessionId();

    if (sessionId == null) {
      throw Exception('Not authenticated');
    }

    // Make API request with session ID in header
    final response = await http.get(
        Uri.parse('$baseUrl/patients'),
        headers: {
          'Content-Type': 'application/json',
          'X-Session-ID': sessionId
        }
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success']) {
        return List<Map<String, dynamic>>.from(data['patients']);
      } else {
        throw Exception(data['message'] ?? 'Failed to load patients');
      }
    } else {
      throw Exception('Failed to load patients');
    }
  }
}