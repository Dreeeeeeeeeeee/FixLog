import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import '../services/repair_service.dart';
import '../widgets/loading_overlay.dart';

class StatusUpdateScreen extends StatefulWidget {
  final Repair repair;

  const StatusUpdateScreen({super.key, required this.repair});

  @override
  State<StatusUpdateScreen> createState() => _StatusUpdateScreenState();
}

class _StatusUpdateScreenState extends State<StatusUpdateScreen> {
  late RepairStatus _newStatus;
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _newStatus = widget.repair.status;
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    try {
      final emailSent = await showLoadingOverlay(
        context,
        message: 'Updating status...',
        future: RepairService.instance.updateStatus(
          widget.repair,
          newStatus: _newStatus,
          note: _notesController.text,
        ),
      );
      if (!mounted) return;
      final hasEmail = widget.repair.customerEmail != null &&
          widget.repair.customerEmail!.trim().isNotEmpty;
      if (hasEmail && emailSent == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated, but the email notification failed to send.'),
            duration: Duration(seconds: 2),
          ),
        );
        await Future.delayed(const Duration(milliseconds: 900));
        if (!mounted) return;
      }
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repair = widget.repair;
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
          'Update Status',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRepairSummaryCard(repair),
              const SizedBox(height: 20),
              Text(
                'Current Status',
                style: TextStyle(
                    color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StatusBadge(status: repair.status),
              const SizedBox(height: 20),
              Text(
                'New Status',
                style: TextStyle(
                    color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _buildStatusDropdown(),
              const SizedBox(height: 20),
              Text(
                'Notes (optional)',
                style: TextStyle(
                    color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              _buildNotesField(),
              const SizedBox(height: 14),
              if (repair.customerEmail != null && repair.customerEmail!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.mail_outline_rounded,
                        size: 14, color: AppColors.greyText),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'An email update will be sent to ${repair.customerEmail}',
                        style: TextStyle(color: AppColors.greyText, fontSize: 12),
                      ),
                    ),
                  ],
                )
              else
                Text(
                  'No customer email on file — they won\'t get an email notification.',
                  style: TextStyle(color: AppColors.greyText, fontSize: 12),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleUpdate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Update Status',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepairSummaryCard(Repair repair) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(repair.icon, color: AppColors.greyText, size: 30),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repair ${repair.id}',
                style: TextStyle(
                    color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                '${repair.customerName} • ${repair.deviceName}',
                style: TextStyle(color: AppColors.greyText, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: DropdownButtonFormField<RepairStatus>(
        value: _newStatus,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.greyText),
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
        items: RepairStatus.values
            .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
            .toList(),
        onChanged: (v) {
          if (v != null) setState(() => _newStatus = v);
        },
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inputBorder),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: TextStyle(color: AppColors.darkText, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Add notes...',
          hintStyle: TextStyle(color: AppColors.greyText, fontSize: 14),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
        ),
      ),
    );
  }
}
