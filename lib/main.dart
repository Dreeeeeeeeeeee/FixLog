import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_colors.dart';
import 'theme/theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const FixLogApp());
}

class FixLogApp extends StatelessWidget {
  const FixLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'FixLog',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            scaffoldBackgroundColor: const Color(0xFFF5F7FB),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FED)),
            fontFamily: 'Roboto',
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: AppColors.darkBackground,
            canvasColor: AppColors.darkSurface,
            dividerColor: AppColors.darkBorder,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.darkPrimary,
              brightness: Brightness.dark,
            ).copyWith(
              primary: AppColors.darkPrimary,
              surface: AppColors.darkSurface,
              onSurface: AppColors.darkTextPrimary,
              outline: AppColors.darkBorder,
            ),
            fontFamily: 'Roboto',
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}
