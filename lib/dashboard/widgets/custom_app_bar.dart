import 'package:flutter/material.dart';
import '../../features/auth/screens/login_screen.dart';
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
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

  Future<void> _logout() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    await _storageService.clearAll();

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
                    height: 850,
                    constraints: BoxConstraints( // Added height constraint
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
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
                    child: SingleChildScrollView( // Added for scrollability
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildMenuItem(
                              icon: Icons.receipt_outlined,
                              label: 'Billing',
                              onTap: () => Navigator.pop(context),
                            ),
                            _buildMenuItem(
                              icon: Icons.settings_outlined,
                              label: 'Settings',
                              onTap: () => Navigator.pop(context),
                            ),
                            _buildMenuItem(
                              icon: Icons.info_outline,
                              label: 'About',
                              onTap: () => Navigator.pop(context),
                            ),
                            _buildMenuItem(
                              icon: Icons.help_outline,
                              label: 'Help',
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
          color: (iconColor ?? const Color(0xFF4CAF50)).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: iconColor ?? const Color(0xFF4CAF50),
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
      backgroundColor: const Color(0xFF4CAF50),
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
        child: _showSearchBar
            ? TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
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
            child: _showSearchBar
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