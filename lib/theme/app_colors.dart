import 'package:flutter/material.dart';
import 'theme_controller.dart';

/// Centralized color palette for the FixLog app.
///
/// Every color below switches automatically between its light and dark
/// value depending on [ThemeController.isDark], so screens just keep using
/// `AppColors.something` and get the right shade. (Because of that, widgets
/// that use these colors can't be `const`.)
///
/// Dark values follow the "FixLog Dark Mode Color Palette" design:
///   Background #0F172A · Surface #1E293B · Border #334155
///   Text primary #F1F5F9 · secondary #94A3B8
///   Primary #3B82F6 · Success #22C55E · Warning #F59E0B · Error #EF4444
class AppColors {
  AppColors._();

  // Raw dark palette values (also used directly by the dark ThemeData).
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkPrimary = Color(0xFF3B82F6);
  static const Color darkPrimaryHover = Color(0xFF2563EB);

  static bool get _dark => ThemeController.isDark;

  // Same in both modes.
  static const Color white = Color(0xFFFFFFFF);
  static const Color dotInactive = Color(0x4DFFFFFF); // white @ 30%

  // App bar, drawer and splash background.
  static Color get navyBackground => _dark ? darkSurface : const Color(0xFF0E1B3D);

  // Buttons, links, active states.
  static Color get primaryBlue => _dark ? darkPrimary : const Color(0xFF2F6FED);

  // Main screen background.
  static Color get lightBackground => _dark ? darkBackground : const Color(0xFFF5F7FB);

  // Text colors (primary text, then muted text).
  static Color get darkText => _dark ? darkTextPrimary : const Color(0xFF0E1B3D);
  static Color get greyText => _dark ? darkTextSecondary : const Color(0xFF8A93A6);

  // Input fields and cards.
  static Color get inputFill => _dark ? darkSurface : const Color(0xFFFFFFFF);
  static Color get inputBorder => _dark ? darkBorder : const Color(0xFFE1E5EE);
  static Color get cardSurface => _dark ? darkSurface : const Color(0xFFFFFFFF);

  // Status accents (icon/number/text color) + their soft tinted backgrounds.
  static Color get statBlue => _dark ? darkPrimary : const Color(0xFF2F6FED);
  static Color get statBlueBg => _dark ? const Color(0xFF1B2E4F) : const Color(0xFFE8F0FE);

  static Color get statOrange => _dark ? const Color(0xFFF59E0B) : const Color(0xFFF5941F);
  static Color get statOrangeBg => _dark ? const Color(0xFF3B2F17) : const Color(0xFFFDF0DF);

  static Color get statPurple => _dark ? const Color(0xFFA78BFA) : const Color(0xFF9B51E0);
  static Color get statPurpleBg => _dark ? const Color(0xFF2A2650) : const Color(0xFFF2E8FC);

  static Color get statGreen => _dark ? const Color(0xFF22C55E) : const Color(0xFF2FA84F);
  static Color get statGreenBg => _dark ? const Color(0xFF12352A) : const Color(0xFFE4F6E9);

  static Color get statRed => _dark ? const Color(0xFFEF4444) : const Color(0xFFE0507A);
  static Color get statRedBg => _dark ? const Color(0xFF3A1F26) : const Color(0xFFFCE8ED);

  // Drawer: active item highlight and inactive text.
  static Color get drawerActiveBg => _dark ? darkPrimaryHover : const Color(0xFF2F6FED);
  static Color get drawerInactiveText =>
      _dark ? darkTextSecondary : const Color(0xFFB9C0D4);
}
