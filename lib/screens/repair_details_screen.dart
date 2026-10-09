import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';
import 'edit_repair_screen.dart';
import 'status_update_screen.dart';
import 'repair_history_screen.dart';
import 'repair_receipt_screen.dart';
import '../widgets/confirm_dialog.dart';
import '../widgets/loading_overlay.dart';
import '../services/repair_service.dart';

class RepairDetailsScreen extends StatelessWidget {
  final Repair repair;

  const RepairDetailsScreen({super.key, required this.repair});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: StreamBuilder<Repair?>(
        stream: RepairService.instance.watchOne(repair.docId),
        initialData: repair,
        builder: (context, snapshot) {
          final current = snapshot.data ?? repair;
          return _buildScaffoldBody(context, current);
        },
      ),
    );
  }

  Widget _buildScaffoldBody(BuildContext context, Repair repair) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: AppColors.navyBackground,
          elevation: 0,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Repair Details',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.receipt_long_rounded, color: AppColors.white),
              tooltip: 'View Receipt',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RepairReceiptScreen(repair: repair)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.history_rounded, color: AppColors.white),
              tooltip: 'View History',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RepairHistoryScreen(repair: repair)),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.white),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => EditRepairScreen(repair: repair)),
                );
              },
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverToBoxAdapter(
            child: Container(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        repair.id,
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      StatusBadge(status: repair.status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(repair.icon, color: AppColors.greyText, size: 30),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repair.deviceName,
                            style: TextStyle(
                              color: AppColors.darkText,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            repair.customerName,
                            style: TextStyle(color: AppColors.greyText, fontSize: 13),
                          ),
                          if (repair.contactNumber != null)
                            Text(
                              repair.contactNumber!,
                              style: TextStyle(color: AppColors.greyText, fontSize: 13),
                            ),
                          if (repair.customerEmail != null && repair.customerEmail!.isNotEmpty)
                            Text(
                              repair.customerEmail!,
                              style: TextStyle(color: AppColors.greyText, fontSize: 13),
                            ),
                        ],
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Divider(height: 1, color: AppColors.inputBorder),
                  ),
                  _buildSection(
                      'Device', '${repair.brand ?? ''} ${repair.model ?? ''}'.trim()),
                  const SizedBox(height: 14),
                  _buildSection('Problem', repair.problemDescription ?? '—'),
                  const SizedBox(height: 14),
                  _buildSection('Date Received', repair.dateReceived ?? '—'),
                  const SizedBox(height: 14),
                  _buildSection('Notes', repair.notes ?? '—'),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => StatusUpdateScreen(repair: repair)),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text('Update Status',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmDelete(context, repair),
                      icon: Icon(Icons.delete_outline_rounded,
                          color: AppColors.statRed, size: 18),
                      label: Text('Delete Repair',
                          style:
                              TextStyle(color: AppColors.statRed, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.statRedBg,
                        side: BorderSide(color: AppColors.statRed.withOpacity(0.3)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
              color: AppColors.greyText, fontSize: 12, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
              color: AppColors.darkText, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Repair repair) async {
    final confirmed = await showAppConfirmDialog(
      context,
      title: 'Delete Repair',
      message:
          'Are you sure you want to delete this repair record?\nThis action cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (confirmed != true || !context.mounted) return;

    try {
      await showLoadingOverlay(
        context,
        message: 'Deleting repair...',
        future: RepairService.instance.deleteRepair(repair),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(); // back to repairs list
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete repair: $e')),
      );
    }
  }
}
