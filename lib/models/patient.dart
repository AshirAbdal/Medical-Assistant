// lib/models/patient.dart
class Patient {
  final int id;
  final String patientId;
  final String name;
  final int? age;
  final String? gender;
  final String? email;
  final String? phone;
  final String? address;
  final String? medicalHistory;
  final String? notes;
  final int? categoryId;
  final String? categoryName;

  Patient({
    required this.id,
    required this.patientId,
    required this.name,
    this.age,
    this.gender,
    this.email,
    this.phone,
    this.address,
    this.medicalHistory,
    this.notes,
    this.categoryId,
    this.categoryName,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id'],
      patientId: json['patient_id'],
      name: json['name'],
      age: json['age'],
      gender: json['gender'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      medicalHistory: json['medical_history'],
      notes: json['notes'],
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'name': name,
      'age': age,
      'gender': gender,
      'email': email,
      'phone': phone,
      'address': address,
      'medical_history': medicalHistory,
      'notes': notes,
      'category_id': categoryId,
    };
  }
}