import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/repair.dart';

class RepairReceiptScreen extends StatelessWidget {
  final Repair repair;

  const RepairReceiptScreen({super.key, required this.repair});

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
          'Repair Receipt',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(20),
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
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.build_rounded, color: AppColors.white, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'FixLog',
                      style: TextStyle(
                          color: AppColors.darkText, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Repair Receipt',
                  style: TextStyle(color: AppColors.greyText, fontSize: 13),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppColors.inputBorder),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repair ${repair.id}',
                      style: TextStyle(
                          color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      repair.dateReceived ?? repair.date ?? '—',
                      style: TextStyle(color: AppColors.greyText, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _receiptRow('Customer:', repair.customerName),
                _receiptRow('Contact:', repair.contactNumber ?? '—'),
                if (repair.customerEmail != null && repair.customerEmail!.isNotEmpty)
                  _receiptRow('Email:', repair.customerEmail!),
                _receiptRow(
                  'Device:',
                  '${repair.deviceName}${repair.brand != null ? ' (${repair.brand} ${repair.model ?? ''})' : ''}'
                      .trim(),
                ),
                const SizedBox(height: 8),
                _receiptRow('Problem:', repair.problemDescription ?? '—'),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(height: 1, color: AppColors.inputBorder),
                ),
                _receiptRow('Actual Cost:', repair.actualCost ?? '—'),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Status:',
                          style: TextStyle(color: AppColors.greyText, fontSize: 13)),
                      StatusBadge(status: repair.status),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thank you for choosing FixLog!',
                  style: TextStyle(color: AppColors.greyText, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Hook up real sharing (share_plus, PDF export, etc.) here.
                    },
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share Receipt',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
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

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: AppColors.greyText, fontSize: 13)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: AppColors.darkText, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
