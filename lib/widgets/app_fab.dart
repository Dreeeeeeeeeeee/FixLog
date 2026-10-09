import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// The blue "+" button used on the main screens to add a new repair.
class AppFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AppFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: AppColors.primaryBlue,
      elevation: 2,
      onPressed: onPressed,
      child: const Icon(Icons.add_rounded, color: AppColors.white),
    );
  }
}
