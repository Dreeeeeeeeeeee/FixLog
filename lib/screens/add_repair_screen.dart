import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../services/repair_service.dart';
import '../services/auth_service.dart';
import '../widgets/loading_overlay.dart';

class AddRepairScreen extends StatefulWidget {
  const AddRepairScreen({super.key});

  @override
  State<AddRepairScreen> createState() => _AddRepairScreenState();
}

class _AddRepairScreenState extends State<AddRepairScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customerNameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _problemController = TextEditingController();

  String? _deviceType;
  final List<String> _deviceTypes = const ['Laptop', 'Phone', 'Desktop', 'Tablet', 'Other'];

  @override
  void dispose() {
    _customerNameController.dispose();
    _contactNumberController.dispose();
    _customerEmailController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _problemController.dispose();
    super.dispose();
  }

  String _formatToday() {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final now = DateTime.now();
    return '${months[now.month - 1]} ${now.day}, ${now.year}';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = AuthService.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be signed in to add a repair.')),
      );
      return;
    }

    final newRepair = Repair(
      docId: '', // ignored by addRepair — Firestore assigns the real ID
      id: '', // ignored by addRepair — RepairService generates the ticket number
      deviceName: _deviceType!,
      customerName: _customerNameController.text.trim(),
      status: RepairStatus.pending,
      date: _formatToday(),
      contactNumber: _contactNumberController.text.trim(),
      customerEmail: _customerEmailController.text.trim(),
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      problemDescription: _problemController.text.trim(),
      dateReceived: _formatToday(),
    );

    try {
      await showLoadingOverlay(
        context,
        message: 'Saving repair...',
        future: RepairService.instance.addRepair(newRepair, createdByUid: uid),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save repair: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      appBar: AppBar(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppColors.darkText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Add Repair',
          style: TextStyle(color: AppColors.darkText, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLabel('Customer Name'),
                _buildTextField(
                  controller: _customerNameController,
                  hint: 'Enter customer name',
                  icon: Icons.person_outline_rounded,
                ),
                const SizedBox(height: 16),

                _buildLabel('Contact Number'),
                _buildTextField(
                  controller: _contactNumberController,
                  hint: 'Enter contact number',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),

                _buildLabel('Customer Email'),
                _buildTextField(
                  controller: _customerEmailController,
                  hint: 'Enter customer email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 16),

                _buildLabel('Device Type'),
                _buildDropdown(),
                const SizedBox(height: 16),

                _buildLabel('Brand'),
                _buildTextField(
                  controller: _brandController,
                  hint: 'Enter brand',
                  icon: Icons.sell_outlined,
                ),
                const SizedBox(height: 16),

                _buildLabel('Model'),
                _buildTextField(
                  controller: _modelController,
                  hint: 'Enter model',
                  icon: Icons.tag_outlined,
                ),
                const SizedBox(height: 16),

                _buildLabel('Problem Description'),
                _buildTextField(
                  controller: _problemController,
                  hint: 'Enter problem description',
                  icon: Icons.description_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save Repair',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
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
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: AppColors.darkText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(text: ' *', style: TextStyle(color: AppColors.statRed)),
          ],
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    final emailRegex = RegExp(r'^[\w.\-+]+@[\w\-]+\.[\w\-.]+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
        maxLines: maxLines,
        validator: validator ??
            (value) => (value == null || value.trim().isEmpty) ? 'This field is required' : null,
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
          prefixIcon: Padding(
            padding: EdgeInsets.only(bottom: maxLines > 1 ? 60 : 0),
            child: Icon(icon, color: AppColors.greyText, size: 20),
          ),
          border: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: _deviceType,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greyText),
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        validator: (value) => value == null ? 'Please select a device type' : null,
        decoration: InputDecoration(
          hintText: 'Select device type',
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
          prefixIcon: Icon(Icons.devices_outlined, color: AppColors.greyText, size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        items: _deviceTypes
            .map((type) => DropdownMenuItem(value: type, child: Text(type)))
            .toList(),
        onChanged: (value) => setState(() => _deviceType = value),
      ),
    );
  }
}
