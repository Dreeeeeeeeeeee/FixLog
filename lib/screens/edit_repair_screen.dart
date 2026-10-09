import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../services/repair_service.dart';
import '../widgets/loading_overlay.dart';

class EditRepairScreen extends StatefulWidget {
  final Repair repair;

  const EditRepairScreen({super.key, required this.repair});

  @override
  State<EditRepairScreen> createState() => _EditRepairScreenState();
}

class _EditRepairScreenState extends State<EditRepairScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerNameController;
  late final TextEditingController _contactNumberController;
  late final TextEditingController _customerEmailController;
  late final TextEditingController _problemController;
  late final TextEditingController _modelController;

  String? _deviceType;
  String? _brand;

  final List<String> _deviceTypes = const ['Laptop', 'Phone', 'Desktop', 'Tablet', 'Other'];
  final List<String> _brands = const ['Acer', 'Asus', 'Apple', 'Dell', 'HP', 'Lenovo', 'Samsung'];

  @override
  void initState() {
    super.initState();
    final r = widget.repair;
    _customerNameController = TextEditingController(text: r.customerName);
    _contactNumberController = TextEditingController(text: r.contactNumber ?? '');
    _customerEmailController = TextEditingController(text: r.customerEmail ?? '');
    _problemController = TextEditingController(text: r.problemDescription ?? '');
    _modelController = TextEditingController(text: r.model ?? '');
    _deviceType = _deviceTypes.contains(r.deviceName) ? r.deviceName : null;
    _brand = r.brand != null && _brands.contains(r.brand) ? r.brand : null;
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _contactNumberController.dispose();
    _customerEmailController.dispose();
    _problemController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedFields = {
      'customerName': _customerNameController.text.trim(),
      'contactNumber': _contactNumberController.text.trim(),
      'customerEmail': _customerEmailController.text.trim(),
      'deviceName': _deviceType,
      'brand': _brand,
      'model': _modelController.text.trim(),
      'problemDescription': _problemController.text.trim(),
    };

    try {
      await showLoadingOverlay(
        context,
        message: 'Saving changes...',
        future: RepairService.instance.updateRepair(widget.repair.docId, updatedFields),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save changes: $e')),
      );
    }
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
          'Edit Repair',
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
                  hint: 'Enter 11-digit contact number',
                  icon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  validator: _phoneValidator,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
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
                _buildDropdown(
                  value: _deviceType,
                  items: _deviceTypes,
                  hint: 'Select device type',
                  icon: Icons.devices_outlined,
                  onChanged: (v) => setState(() => _deviceType = v),
                ),
                const SizedBox(height: 16),

                _buildLabel('Brand'),
                _buildDropdown(
                  value: _brand,
                  items: _brands,
                  hint: 'Select brand',
                  icon: Icons.sell_outlined,
                  onChanged: (v) => setState(() => _brand = v),
                ),
                const SizedBox(height: 16),

                _buildLabel('Model', required: false),
                _buildTextField(
                  controller: _modelController,
                  hint: 'Enter model (optional)',
                  icon: Icons.tag_outlined,
                  validator: (value) => null,
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: const Text('Save Changes',
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

  Widget _buildLabel(String text, {bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          text: text,
          style: TextStyle(
              color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
          children: [
            if (required)
              TextSpan(text: ' *', style: TextStyle(color: AppColors.statRed))
            else
              TextSpan(
                text: ' (optional)',
                style: TextStyle(color: AppColors.greyText, fontWeight: FontWeight.normal),
              ),
          ],
        ),
      ),
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    final emailRegex = RegExp(r'^[\w.\-+]+@[\w\-]+(\.[\w\-]+)*\.[A-Za-z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'This field is required';
    if (!RegExp(r'^[0-9]{11}$').hasMatch(value.trim())) {
      return 'Enter an 11-digit phone number';
    }
    return null;
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    List<TextInputFormatter>? inputFormatters,
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
        inputFormatters: inputFormatters,
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

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required IconData icon,
    required ValueChanged<String?> onChanged,
    bool required = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greyText),
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        validator: required ? (v) => v == null ? 'Please make a selection' : null : null,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.greyText, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
        items: items.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
        onChanged: onChanged,
      ),
    );
  }
}