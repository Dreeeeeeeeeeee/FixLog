import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shows a dimmed, non-dismissible loading overlay with a centered
/// spinner card, matching the app's "Loading State" mockup.
///
/// Waits for [future] to complete (if given), otherwise waits for
/// [minDuration], then closes itself automatically.
Future<T?> showLoadingOverlay<T>(
  BuildContext context, {
  String message = 'Loading...',
  Future<T>? future,
  Duration minDuration = const Duration(milliseconds: 800),
}) async {
  final navigator = Navigator.of(context, rootNavigator: true);

  // Intentionally not awaited — this opens the overlay and returns
  // immediately so we can await the actual work below.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.35),
    builder: (_) => _LoadingCard(message: message),
  );

  T? result;
  if (future != null) {
    final results = await Future.wait([future, Future.delayed(minDuration)]);
    result = results[0] as T;
  } else {
    await Future.delayed(minDuration);
  }

  navigator.pop();
  return result;
}

class _LoadingCard extends StatelessWidget {
  final String message;

  const _LoadingCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation(AppColors.primaryBlue),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                color: AppColors.darkText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
