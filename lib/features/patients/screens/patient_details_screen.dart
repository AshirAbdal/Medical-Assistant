// lib/features/patients/screens/patient_details_screen.dart
import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../models/patient.dart';
import '../../../services/patient_service.dart';

class PatientDetailsScreen extends StatefulWidget {
  final Patient patient;

  const PatientDetailsScreen({super.key, required this.patient});

  @override
  State<PatientDetailsScreen> createState() => _PatientDetailsScreenState();
}

class _PatientDetailsScreenState extends State<PatientDetailsScreen> {
  late Patient patient;
  bool _isEditing = false;
  bool _isLoading = false;
  List<Category> categories = [];
  Category? selectedCategory;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController ageController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController addressController;
  late TextEditingController notesController;
  String? selectedGender;

  final PatientService _patientService = PatientService(
    baseUrl: 'http://localhost/my_patients_api', // Update with your API URL
  );

  @override
  void initState() {
    super.initState();
    patient = widget.patient;
    _initControllers();
    _loadCategories();
  }

  void _initControllers() {
    nameController = TextEditingController(text: patient.name);
    ageController = TextEditingController(text: patient.age?.toString() ?? '');
    emailController = TextEditingController(text: patient.email ?? '');
    phoneController = TextEditingController(text: patient.phone ?? '');
    addressController = TextEditingController(text: patient.address ?? '');
    notesController = TextEditingController(text: patient.notes ?? '');
    selectedGender = patient.gender;
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final categoriesList = await _patientService.getCategories();

      setState(() {
        categories = categoriesList;

        // Set selected category if patient has one
        if (patient.categoryId != null) {
          selectedCategory = categories.firstWhere(
                (category) => category.id == patient.categoryId,
            orElse: () => categories.first,
          );
        }

        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading categories: ${e.toString()}')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePatient() async {
    if (_formKey.currentState!.validate()) {
      try {
        setState(() {
          _isLoading = true;
        });

        final updatedData = {
          'name': nameController.text,
          'age': ageController.text.isNotEmpty ? int.parse(ageController.text) : null,
          'gender': selectedGender,
          'email': emailController.text.isNotEmpty ? emailController.text : null,
          'phone': phoneController.text.isNotEmpty ? phoneController.text : null,
          'address': addressController.text.isNotEmpty ? addressController.text : null,
          'notes': notesController.text.isNotEmpty ? notesController.text : null,
          'category_id': selectedCategory?.id,
        };

        final updatedPatient = await _patientService.updatePatient(
          patient.id,
          updatedData,
        );

        setState(() {
          patient = updatedPatient;
          _isEditing = false;
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient updated successfully')),
        );
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deletePatient() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${patient.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() {
          _isLoading = true;
        });

        await _patientService.deletePatient(patient.id);

        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient deleted successfully')),
        );

        Navigator.pop(context, true); // Return true to trigger refresh
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Patient' : 'Patient Details'),
        backgroundColor: const Color(0xFF4caf50),
        foregroundColor: Colors.white,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _updatePatient,
            ),
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deletePatient,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isEditing
          ? _buildEditForm()
          : _buildPatientDetails(),
    );
  }

  Widget _buildPatientDetails() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient ID and basic info card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: patient.gender == 'Female'
                            ? Colors.pink
                            : Colors.blue,
                        radius: 30,
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Patient ID: ${patient.patientId}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  _buildInfoRow('Age', patient.age?.toString() ?? 'Not specified'),
                  _buildInfoRow('Gender', patient.gender ?? 'Not specified'),
                  if (patient.categoryName != null)
                    _buildInfoRow('Category', patient.categoryName!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Contact information card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Email', patient.email ?? 'Not provided'),
                  _buildInfoRow('Phone', patient.phone ?? 'Not provided'),
                  _buildInfoRow('Address', patient.address ?? 'Not provided'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Notes card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    patient.notes ?? 'No notes available',
                    style: TextStyle(
                      color: patient.notes == null ? Colors.grey : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Medical history card (if implemented)
          if (patient.medicalHistory != null && patient.medicalHistory!.isNotEmpty)
            Column(
              children: [
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Medical History',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(patient.medicalHistory!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name field
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter patient name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Age field
            TextFormField(
              controller: ageController,
              decoration: const InputDecoration(
                labelText: 'Age',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Gender dropdown
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(),
              ),
              value: selectedGender,
              items: const [
                DropdownMenuItem(value: 'Male', child: Text('Male')),
                DropdownMenuItem(value: 'Female', child: Text('Female')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedGender = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // Category dropdown
            if (categories.isNotEmpty)
              DropdownButtonFormField<Category>(
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                value: selectedCategory,
                items: categories.map((category) {
                  return DropdownMenuItem<Category>(
                    value: category,
                    child: Text(category.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value;
                  });
                },
              ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),

            // Phone field
            TextFormField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Address field
            TextFormField(
              controller: addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Notes field
            TextFormField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      setState(() {
                        _isEditing = false;
                        // Reset controllers to original values
                        _initControllers();
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4caf50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _updatePatient,
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    notesController.dispose();
    super.dispose();
  }
}