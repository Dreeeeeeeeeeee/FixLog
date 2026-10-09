import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../widgets/app_drawer.dart';
import '../widgets/confirm_dialog.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'login_screen.dart';
import 'app_preferences_screen.dart';
import 'help_support_screen.dart';
import 'about_screen.dart';
import 'manage_technicians_screen.dart';
import 'account_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      drawer: const AppDrawer(activeItem: DrawerItem.settings),
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildProfileCard(),
            const SizedBox(height: 16),
            _buildSettingsGroup(context),
            const SizedBox(height: 20),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final user = AuthService.instance.currentUser;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.inputBorder,
            child: Icon(Icons.person, color: AppColors.primaryBlue, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: user == null
                ? Text('Not signed in',
                    style: TextStyle(color: AppColors.greyText, fontSize: 13))
                : StreamBuilder<TechnicianProfile?>(
                    stream: UserService.instance.watchProfile(user.uid),
                    builder: (context, snapshot) {
                      final profile = snapshot.data;
                      final name = profile?.name ?? 'Technician';
                      final email = profile?.email ?? user.email ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            email,
                            style: TextStyle(color: AppColors.greyText, fontSize: 13),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(BuildContext context) {
    return FutureBuilder<bool>(
      future: UserService.instance.isCurrentUserAdmin(),
      builder: (context, snapshot) {
        final isAdmin = snapshot.data ?? false;

        return Container(
          decoration: BoxDecoration(
            color: AppColors.cardSurface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSettingsItem(
                icon: Icons.person_outline_rounded,
                label: 'Account Settings',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountSettingsScreen()),
                  );
                },
              ),
              if (isAdmin) ...[
                _divider(),
                _buildSettingsItem(
                  icon: Icons.group_add_outlined,
                  label: 'Manage Technicians',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ManageTechniciansScreen()),
                    );
                  },
                ),
              ],
              _divider(),
              _buildSettingsItem(
                icon: Icons.settings_outlined,
                label: 'App Preferences',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AppPreferencesScreen()),
                  );
                },
              ),
              _divider(),
              _buildSettingsItem(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                  );
                },
              ),
              _divider(),
              _buildSettingsItem(
                icon: Icons.error_outline_rounded,
                label: 'About',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AboutScreen()),
                  );
                },
                isLast: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _divider() => Divider(height: 1, color: AppColors.inputBorder, indent: 16);

  Widget _buildSettingsItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.darkText, size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppColors.darkText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.greyText),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: Icon(Icons.logout_rounded, color: AppColors.statRed, size: 18),
        label: Text(
          'Logout',
          style: TextStyle(color: AppColors.statRed, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.statRedBg,
          side: BorderSide(color: AppColors.statRed.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You will need to sign in again to access your account.',
      confirmLabel: 'Logout',
      icon: Icons.logout_rounded,
    );
    if (confirmed == true) {
      await AuthService.instance.signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }
}
