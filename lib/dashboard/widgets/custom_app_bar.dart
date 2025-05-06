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

  void _showModernBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle indicator
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Menu items
              _buildMenuTile(
                icon: Icons.receipt_outlined,
                title: 'Billing',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to billing page
                },
              ),

              _buildMenuTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings page
                },
              ),

              _buildMenuTile(
                icon: Icons.info_outline,
                title: 'About',
                onTap: () {
                  Navigator.pop(context);
                  // Show about dialog
                },
              ),

              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'Help',
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to help page
                },
              ),

              const Divider(height: 10, thickness: 1),

              _buildMenuTile(
                icon: Icons.logout_rounded,
                title: 'Logout',
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF4caf50)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFF4caf50),
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.black87,
        ),
      ),
      onTap: onTap,
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey[400],
      ),
    );
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
        // Modern 3-dot menu
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showModernBottomSheet,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}