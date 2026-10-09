import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Show the splash for a moment, then route based on whether
    // there's already a signed-in Firebase session.
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final isSignedIn = AuthService.instance.currentUser != null;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => isSignedIn ? const DashboardScreen() : const LoginScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyBackground,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),
            // Logo tile
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.build_rounded,
                color: AppColors.white,
                size: 44,
              ),
            ),
            const SizedBox(height: 24),
            // App name
            const Text(
              'FixLog',
              style: TextStyle(
                color: AppColors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 8),
            // Tagline
            Text(
              'Track. Repair. Get It Fixed.',
              style: TextStyle(
                color: AppColors.greyText,
                fontSize: 14,
              ),
            ),
            const Spacer(flex: 3),
            // Page indicator dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildDot(active: true),
                _buildDot(active: false),
                _buildDot(active: false),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDot({required bool active}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? AppColors.primaryBlue : AppColors.dotInactive,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
