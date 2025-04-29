import 'package:flutter/material.dart';
import '../../features/auth/screens/LoginScreen.dart';
import '../../services/storage_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final StorageService _storageService = StorageService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Logout function
  Future<void> _logout() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    // Clear stored user data
    await _storageService.clearAll();

    // Close loading dialog
    if (mounted) {
      Navigator.of(context).pop();
    }

    // Navigate to login screen
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Loginscreen()),
            (route) => false, // This removes all previous routes
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF4caf50),
      elevation: 0,
      // Logo on the left (without back functionality)
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/logo.png',
          width: 40,
          height: 40,
        ),
      ),
      // Title or search bar in the middle
      title: _showSearchBar
          ? TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search patients...',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
        style: const TextStyle(color: Colors.white),
        cursorColor: Colors.white,
      )
          : Text(
        widget.title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      centerTitle: true,
      // Search icon and 3-dot menu on the right
      actions: [
        // Search icon
        IconButton(
          icon: Icon(
            _showSearchBar ? Icons.close : Icons.search,
            color: Colors.white,
          ),
          onPressed: () {
            setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) {
                _searchController.clear();
              }
            });
          },
        ),
        // 3-dot menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            // Handle menu item selection
            switch (value) {
              case 'billing':
              // Navigate to billing page
                break;
              case 'settings':
              // Navigate to settings page
                break;
              case 'about':
              // Show about dialog
                break;
              case 'help':
              // Navigate to help page
                break;
              case 'logout':
                _logout();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'billing',
              child: Text('Billing'),
            ),
            const PopupMenuItem<String>(
              value: 'settings',
              child: Text('Settings'),
            ),
            const PopupMenuItem<String>(
              value: 'about',
              child: Text('About'),
            ),
            const PopupMenuItem<String>(
              value: 'help',
              child: Text('Help'),
            ),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Text('Logout'),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}