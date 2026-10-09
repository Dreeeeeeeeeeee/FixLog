import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_colors.dart';

/// TODO: replace with your real support contact details.
const String kSupportEmail = 'andrejohn01234@gmail.com';
const String kSupportPhone = '+63 991 536 6394';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launch(BuildContext context, Uri uri) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that app on this device.')),
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
          'Help & Support',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Need help with FixLog? Reach out to us directly:',
              style: TextStyle(color: AppColors.greyText, fontSize: 13),
            ),
            const SizedBox(height: 16),
            _buildContactTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: kSupportEmail,
              onTap: () => _launch(context, Uri(scheme: 'mailto', path: kSupportEmail)),
            ),
            _buildContactTile(
              icon: Icons.call_outlined,
              label: 'Phone',
              value: kSupportPhone,
              onTap: () => _launch(
                context,
                Uri(scheme: 'tel', path: kSupportPhone.replaceAll(' ', '')),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'FAQs',
              style: TextStyle(
                color: AppColors.darkText,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            _buildFaqTile(
              'How do I add a new repair?',
              'Tap the blue + button on the Home, Repairs, or History screen to open the Add Repair form.',
            ),
            _buildFaqTile(
              'How does the customer get notified?',
              'When you update a repair\'s status, an email is sent automatically to the customer email on file.',
            ),
            _buildFaqTile(
              'Can I undo a status update?',
              'Yes — open the repair and tap Update Status again to change it to the correct status.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
      child: ListTile(
        leading: Icon(icon, color: AppColors.primaryBlue),
        title: Text(label,
            style: TextStyle(color: AppColors.greyText, fontSize: 12)),
        subtitle: Text(value,
            style: TextStyle(
                color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 14)),
        trailing: Icon(Icons.chevron_right_rounded, color: AppColors.greyText),
        onTap: onTap,
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Theme(
      data: ThemeData(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: Text(
          question,
          style: TextStyle(
              color: AppColors.darkText, fontWeight: FontWeight.w600, fontSize: 13),
        ),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        expandedAlignment: Alignment.centerLeft,
        children: [
          Text(
            answer,
            style: TextStyle(color: AppColors.greyText, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
