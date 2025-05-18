import 'package:flutter/material.dart';
import '../../../models/category.dart';
import '../../../models/patient.dart';
import '../../../services/patient_service.dart';
import '../screens/patient_details_screen.dart';
import '../screens/add_patient_screen.dart';

class MyPatientsScreen extends StatefulWidget {
  const MyPatientsScreen({super.key});

  @override
  State<MyPatientsScreen> createState() => _MyPatientsScreenState();
}

class _MyPatientsScreenState extends State<MyPatientsScreen> {
  final PatientService _patientService = PatientService(
    baseUrl: 'http://localhost/my_patients_api', // Update with your API URL
  );

  bool _isLoading = true;
  String? _error;
  List<Patient> patients = [];
  List<Map<String, dynamic>> appointments = [];
  List<Category> categories = [];
  Category? selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print("Starting to load data for MyPatientsScreen");

      // Load all categories first for filter UI
      final categoriesList = await _patientService.getCategories();
      print("All available categories: ${categoriesList.length}");

      // Load patients with optional category filter
      print("Fetching patients with filter: ${selectedCategory?.id}");
      final patientsList = await _patientService.getMyPatients(
        categoryId: selectedCategory?.id,
      );
      print("Patients received: ${patientsList.length}");

      // For debugging: print each patient
      for (var patient in patientsList) {
        print("Patient: ${patient.name}, Category: ${patient.categoryId}");
      }

      if (mounted) {
        setState(() {
          patients = patientsList;
          categories = categoriesList;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error loading data: ${e.toString()}");
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _filterByCategory(Category? category) {
    setState(() {
      selectedCategory = category;
    });
    _loadData();
  }

  Future<void> _navigateToAddPatient() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPatientScreen()),
    );

    if (result == true) {
      // Refresh the list if patient was added
      _loadData();
    }
  }

  Future<void> _navigateToPatientDetails(Patient patient) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDetailsScreen(patient: patient),
      ),
    );

    if (result == true) {
      // Refresh the list if patient was updated/deleted
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category filter chips
        if (categories.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: const Text('All'),
                    selected: selectedCategory == null,
                    onSelected: (selected) {
                      if (selected) {
                        _filterByCategory(null);
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.green[100],
                  ),
                ),
                ...categories.map((category) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(category.name),
                      selected: selectedCategory?.id == category.id,
                      onSelected: (selected) {
                        if (selected) {
                          _filterByCategory(category);
                        } else {
                          _filterByCategory(null);
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.green[100],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

        // Patient list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadData,
            child:
                patients.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            selectedCategory != null
                                ? 'No patients in ${selectedCategory!.name} category'
                                : 'No patients found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add Patient'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4caf50),
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _navigateToAddPatient,
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: patients.length,
                      itemBuilder: (context, index) {
                        final patient = patients[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 1,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  patient.gender == 'Female'
                                      ? Colors.pink
                                      : Colors.blue,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              patient.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  'Age: ${patient.age ?? 'N/A'}   Gender: ${patient.gender ?? 'N/A'}',
                                ),
                                Text('ID: ${patient.patientId}'),
                                if (patient.categoryName != null)
                                  Chip(
                                    label: Text(
                                      patient.categoryName!,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: Colors.green[50],
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                              ],
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _navigateToPatientDetails(patient),
                          ),
                        );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}
