import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/loading_overlay.dart';

class AddTechnicianScreen extends StatefulWidget {
  const AddTechnicianScreen({super.key});

  @override
  State<AddTechnicianScreen> createState() => _AddTechnicianScreenState();
}

class _AddTechnicianScreenState extends State<AddTechnicianScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _role = 'Technician';
  final List<String> _roles = const ['Technician', 'Admin'];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    final emailRegex = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'This field is required';
    if (value.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? _requiredValidator(String? value) {
    return (value == null || value.trim().isEmpty) ? 'This field is required' : null;
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) return;

    final username = _usernameController.text.trim();

    try {
      final future = _createAccount(username);
      await showLoadingOverlay(context, message: 'Creating account...', future: future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_nameController.text.trim()}\'s account was created.')),
      );
      Navigator.of(context).pop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mapAuthError(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create account: $e')),
      );
    }
  }

  Future<void> _createAccount(String username) async {
    if (username.isNotEmpty) {
      final available = await UserService.instance.isUsernameAvailable(username);
      if (!available) {
        throw Exception('That username is already taken.');
      }
    }

    final uid = await AuthService.instance.createTechnicianAccount(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    await UserService.instance.createProfile(
      uid: uid,
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      username: username.isEmpty ? null : username,
      role: _role,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'Add Technician',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Full Name'),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Enter full name',
                  icon: Icons.person_outline_rounded,
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 16),

                _buildLabel('Email'),
                _buildTextField(
                  controller: _emailController,
                  hint: 'Enter email address',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 16),

                _buildLabel('Username (optional)'),
                _buildTextField(
                  controller: _usernameController,
                  hint: 'For logging in without an email',
                  icon: Icons.alternate_email_rounded,
                  required: false,
                ),
                const SizedBox(height: 16),

                _buildLabel('Temporary Password'),
                _buildTextField(
                  controller: _passwordController,
                  hint: 'At least 6 characters',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  validator: _passwordValidator,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.greyText,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Share this password with them directly — they can change it later.',
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
                const SizedBox(height: 16),

                _buildLabel('Role'),
                _buildRoleDropdown(),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleCreate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: TextStyle(
            color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool required = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        validator: required ? (validator ?? _requiredValidator) : null,
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.greyText, size: 20),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: _role,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greyText),
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
        onChanged: (v) {
          if (v != null) setState(() => _role = v);
        },
      ),
    );
  }
}
