import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_overlay.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _nameController = TextEditingController();
  bool _loadedInitialName = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(String uid) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name can\'t be empty.')),
      );
      return;
    }
    try {
      await showLoadingOverlay(
        context,
        message: 'Saving...',
        future: FirebaseFirestore.instance.collection('users').doc(uid).update({'name': name}),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name updated.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update name: $e')),
      );
    }
  }

  Future<void> _handleChangePassword(String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Text(
          'We\'ll send a password reset link to $email. Use it to set a new password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await showLoadingOverlay(
        context,
        message: 'Sending...',
        future: AuthService.instance.sendPasswordResetEmail(email),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.instance.currentUser;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.navyBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: user == null
            ? Center(
                child: Text('Not signed in', style: TextStyle(color: AppColors.greyText)),
              )
            : StreamBuilder<TechnicianProfile?>(
                stream: UserService.instance.watchProfile(user.uid),
                builder: (context, snapshot) {
                  final profile = snapshot.data;
                  if (profile != null && !_loadedInitialName) {
                    _nameController.text = profile.name;
                    _loadedInitialName = true;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColors.statBlueBg,
                              child: Icon(
                                profile?.isAdmin == true
                                    ? Icons.shield_outlined
                                    : Icons.person_outline_rounded,
                                color: AppColors.statBlue,
                                size: 32,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: profile?.isAdmin == true
                                    ? AppColors.statPurpleBg
                                    : AppColors.statBlueBg,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                profile?.role ?? 'Technician',
                                style: TextStyle(
                                  color: profile?.isAdmin == true
                                      ? AppColors.statPurple
                                      : AppColors.statBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildCard(
                        title: 'Profile',
                        children: [
                          _buildLabel('Full Name'),
                          _buildTextField(_nameController, Icons.person_outline_rounded),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => _saveName(user.uid),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primaryBlue),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              child: Text('Save Name',
                                  style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildCard(
                        title: 'Login Details',
                        children: [
                          _buildReadOnlyRow('Email', profile?.email ?? user.email ?? '—'),
                          if (profile?.username != null && profile!.username!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            _buildReadOnlyRow('Username', '@${profile.username}'),
                          ],
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _handleChangePassword(profile?.email ?? user.email ?? ''),
                              icon: Icon(Icons.lock_reset_rounded,
                                  color: AppColors.primaryBlue, size: 18),
                              label: Text('Change Password',
                                  style: TextStyle(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: AppColors.primaryBlue),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
            color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.greyText, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildReadOnlyRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.greyText, fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
