// lib/dashboard/widgets/custom_app_bar.dart
import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../services/auth_service.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? userRole;
  final Map<String, String>? userInfo;

  const CustomAppBar({
    super.key,
    required this.title,
    this.userRole,
    this.userInfo,
  });

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _CustomAppBarState extends State<CustomAppBar> {
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Logout'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Call logout API
    await _authService.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Loginscreen()),
        (route) => false,
      );
    }
  }

  void _showModernMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                behavior: HitTestBehavior.opaque,
              ),
            ),
            Positioned(
              top: kToolbarHeight + MediaQuery.of(context).padding.top + 8,
              right: 16,
              child: ScaleTransition(
                scale: CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                ),
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 340,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // User info section
                            if (widget.userInfo != null)
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: const Color(0xFF4caf50),
                                      radius: 25,
                                      child: Text(
                                        widget.userInfo!['name']
                                                ?.substring(0, 1)
                                                .toUpperCase() ??
                                            'U',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            widget.userInfo!['name'] ?? 'User',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            widget.userInfo!['email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(
                                                widget.userRole,
                                              ).withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              widget.userInfo!['role'] ??
                                                  'Unknown',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: _getRoleColor(
                                                  widget.userRole,
                                                ),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (widget.userInfo != null)
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(height: 24, thickness: 1),
                              ),

                            // Menu items based on permissions
                            if (widget.userRole != 'doctor')
                              _buildMenuItem(
                                icon: Icons.dashboard_outlined,
                                label: 'Admin Dashboard',
                                onTap: () {
                                  Navigator.pop(context);
                                  // Navigate to admin dashboard
                                },
                              ),

                            _buildMenuItem(
                              icon: Icons.receipt_outlined,
                              label: 'Billing',
                              onTap: () {
                                Navigator.pop(context);
                                if (widget.userRole == 'doctor') {
                                  // Show mobile-only message for doctors
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Billing features available in mobile app only',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),

                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onTap: () => Navigator.pop(context),
                            ),

                            _buildMenuItem(
                              icon: Icons.person_outline,
                              label: 'Profile',
                              onTap: () => Navigator.pop(context),
                            ),

                            _buildMenuItem(
                              icon: Icons.info_outline,
                              label: 'About',
                              onTap: () => Navigator.pop(context),
                            ),

                            _buildMenuItem(
                              icon: Icons.help_outline,
                              label: 'Help & Support',
                              onTap: () => Navigator.pop(context),
                            ),

                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Divider(height: 24, thickness: 1),
                            ),

                            _buildMenuItem(
                              icon: Icons.logout,
                              label: 'Logout',
                              iconColor: Colors.red,
                              textColor: Colors.red,
                              onTap: () {
                                Navigator.pop(context);
                                _logout();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Color _getRoleColor(String? role) {
    switch (role) {
      case 'doctor':
        return Colors.blue;
      case 'admin':
        return Colors.orange;
      case 'doctor_admin':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return ListTile(
      dense: true,
      minLeadingWidth: 24,
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: (iconColor ?? const Color(0xFF4caf50)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? const Color(0xFF4caf50),
        ),
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor ?? Colors.grey[800],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey[400],
      ),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF4caf50),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          'assets/images/logo.png',
          filterQuality: FilterQuality.high,
        ),
      ),
      title: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child:
            _showSearchBar
                ? TextField(
                  controller: _searchController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search patients...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  onSubmitted: (value) {
                    // Implement search functionality
                    print('Searching for: $value');
                  },
                )
                : Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child:
                _showSearchBar
                    ? const Icon(Icons.close, color: Colors.white)
                    : const Icon(Icons.search, color: Colors.white),
          ),
          onPressed: () {
            setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) _searchController.clear();
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showModernMenu,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
