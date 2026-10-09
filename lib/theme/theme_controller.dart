import 'package:flutter/material.dart';

/// App-wide dark/light mode switch. main.dart listens to this via
/// ValueListenableBuilder; any screen can flip it (see App Preferences).
class ThemeController {
  ThemeController._();
  static final ValueNotifier<ThemeMode> mode = ValueNotifier(ThemeMode.light);

  static bool get isDark => mode.value == ThemeMode.dark;

  static void setDark(bool dark) {
    mode.value = dark ? ThemeMode.dark : ThemeMode.light;

    // Screens read AppColors while they build, so they wouldn't notice the
    // switch on their own. After the theme change lands, mark every widget
    // for rebuild so the whole app repaints instantly — without losing the
    // current screen, scroll position or navigation stack.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      void rebuild(Element element) {
        element.markNeedsBuild();
        element.visitChildren(rebuild);
      }

      WidgetsBinding.instance.rootElement?.visitChildren(rebuild);
    });
  }
}
