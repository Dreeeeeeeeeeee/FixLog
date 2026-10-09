import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// TODO: replace with your real details / bump on each release.
const String kAppVersion = '1.0.0';
const String kDeveloperName = 'Your Name / Team Name';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
          'About',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.build_rounded, color: AppColors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'FixLog',
                    style: TextStyle(
                        color: AppColors.darkText, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Version $kAppVersion',
                    style: TextStyle(color: AppColors.greyText, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
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
                    'About FixLog',
                    style: TextStyle(
                        color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'FixLog is a repair-tracking app built for repair shops and '
                    'technicians. Track repair tickets from intake to pickup, keep '
                    'customers updated automatically, and see shop performance at a '
                    'glance.',
                    style: TextStyle(color: AppColors.greyText, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
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
                    'Developer',
                    style: TextStyle(
                        color: AppColors.darkText, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    kDeveloperName,
                    style: TextStyle(color: AppColors.greyText, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '© 2026 FixLog. All rights reserved.',
                style: TextStyle(color: AppColors.greyText, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
