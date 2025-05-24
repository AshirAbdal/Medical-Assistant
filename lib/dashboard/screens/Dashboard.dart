// lib/dashboard/screens/Dashboard.dart
import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../../features/patients/screens/my_patients_screen.dart';
import '../../features/patients/screens/all_patients_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';
import '../../features/patients/screens/add_patient_screen.dart';
import '../../services/storage_service.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StorageService _storageService = StorageService();
  
  final List<String> _tabTitles = [];
  final List<Widget> _tabViews = [];
  String? _userRole;
  Map<String, dynamic>? _permissions;
  Map<String, String> _userInfo = {};
  int _currentIndex = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserPermissions();
  }

  Future<void> _loadUserPermissions() async {
    try {
      // Get user role and permissions
      _userRole = await _storageService.getUserRole();
      _permissions = await _storageService.getUserPermissions();
      _userInfo = await _storageService.getUserDisplayInfo();
      
      // Build tabs based on permissions
      _buildTabs();
      
      // Initialize tab controller with the correct number of tabs
      _tabController = TabController(
        length: _tabTitles.length, 
        vsync: this, 
        initialIndex: 0
      );
      
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _currentIndex = _tabController.index;
          });
        }
      });
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user permissions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _buildTabs() {
    _tabTitles.clear();
    _tabViews.clear();
    
    // Always show My Patients for all roles
    _tabTitles.add('My Patients');
    _tabViews.add(const MyPatientsScreen());
    
    // Show All Patients based on permissions
    if (_permissions?['canViewPatients'] == true) {
      _tabTitles.add('All Patients');
      _tabViews.add(const AllPatientsScreen());
    }
    
    // Show Schedule based on permissions
    if (_permissions?['canManageAppointments'] == true) {
      _tabTitles.add('Schedule');
      _tabViews.add(const ScheduleScreen());
    }
    
    // Add more tabs based on permissions
    // For example, if you have billing functionality:
    // if (_permissions?['canViewBilling'] == true) {
    //   _tabTitles.add('Billing');
    //   _tabViews.add(const BillingScreen());
    // }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAccessDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(Icons.lock, color: Colors.red[400], size: 48),
        title: const Text('Access Restricted'),
        content: Text(
          _userRole == 'doctor' 
            ? 'As a doctor, you can only access this feature from the mobile application.'
            : 'You do not have permission to access this feature.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAddPatientDialog() {
    if (_permissions?['canAddPatients'] != true) {
      _showAccessDeniedDialog();
      return;
    }

    // Navigate to AddPatientScreen instead of showing dialog
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddPatientScreen()),
    ).then((result) {
      // Refresh the patients list if a new patient was added
      if (result == true) {
        setState(() {
          // This will trigger a refresh in MyPatientsScreen
        });
      }
    });
  }

  void _showAddAppointmentDialog() {
    if (_permissions?['canManageAppointments'] != true) {
      _showAccessDeniedDialog();
      return;
    }

    // Show dialog to add a new appointment
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Appointment'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Patient Name',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Date',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Time',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.access_time),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Appointment Type',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4caf50),
            ),
            onPressed: () {
              // Add appointment logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment added successfully')),
              );
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF4caf50),
            radius: 30,
            child: Text(
              _userInfo['name']?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, ${_userInfo['name'] ?? 'User'}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _userRole == 'doctor' 
                            ? Colors.blue[100] 
                            : _userRole == 'admin' 
                                ? Colors.orange[100]
                                : Colors.purple[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _userInfo['role'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: _userRole == 'doctor' 
                              ? Colors.blue[800] 
                              : _userRole == 'admin' 
                                  ? Colors.orange[800]
                                  : Colors.purple[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_userRole == 'doctor')
                      const Text(
                        '(Mobile Access Only)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _tabTitles.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.grey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF4caf50)),
              SizedBox(height: 16),
              Text(
                'Loading user permissions...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: _currentIndex < _tabTitles.length ? _tabTitles[_currentIndex] : 'Dashboard',
        userRole: _userRole,
        userInfo: _userInfo,
      ),
      body: Column(
        children: [
          // User info card - only show on first tab
          if (_currentIndex == 0) _buildUserInfoCard(),
          
          // Custom tab navigation
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF4caf50),
              indicatorWeight: 3,
              labelColor: const Color(0xFF4caf50),
              unselectedLabelColor: Colors.grey[600],
              labelStyle: const TextStyle(fontWeight: FontWeight.w500),
              tabs: _tabTitles.map((title) => Tab(text: title)).toList(),
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabViews,
            ),
          ),
        ],
      ),
      // Floating action button - only show if user has add permissions
      floatingActionButton: (_permissions?['canAddPatients'] == true || 
                             _permissions?['canManageAppointments'] == true)
          ? FloatingActionButton(
              backgroundColor: const Color(0xFF4caf50),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                // Add patient or appointment action based on current tab
                if (_currentIndex < _tabTitles.length && 
                    _tabTitles[_currentIndex] == 'Schedule') {
                  _showAddAppointmentDialog();
                } else {
                  _showAddPatientDialog();
                }
              },
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}