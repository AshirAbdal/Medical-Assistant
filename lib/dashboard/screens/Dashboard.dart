import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../../features/patients/screens/my_patients_screen.dart';
import '../../features/patients/screens/all_patients_screen.dart';
import '../../features/schedule/screens/schedule_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabTitles = ['My Patients', 'All Patients', 'Schedule'];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with index 0 (My Patients)
    _tabController = TabController(length: 3, vsync: this, initialIndex: 0);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: _tabTitles[_currentIndex],
      ),
      body: Column(
        children: [
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
              tabs: [
                Tab(text: _tabTitles[0]),
                Tab(text: _tabTitles[1]),
                Tab(text: _tabTitles[2]),
              ],
            ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                MyPatientsScreen(),
                AllPatientsScreen(),
                ScheduleScreen(),
              ],
            ),
          ),
        ],
      ),
      // Floating action button
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () {
          // Add patient or appointment action based on current tab
          if (_currentIndex == 2) {
            // Add appointment
            _showAddAppointmentDialog();
          } else {
            // Add patient
            _showAddPatientDialog();
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showAddPatientDialog() {
    // Show dialog to add a new patient
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Patient'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Full Name'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Gender'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Contact Number'),
                keyboardType: TextInputType.phone,
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
              // Add patient logic here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Patient added successfully')),
              );
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddAppointmentDialog() {
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
                decoration: InputDecoration(labelText: 'Patient Name'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Date'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Time'),
              ),
              SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(labelText: 'Appointment Type'),
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
}