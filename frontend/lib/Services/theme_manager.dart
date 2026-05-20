import 'package:flutter/material.dart';

class AppTheme {
  final String name;
  final Color bgColor;
  final Color textColor;
  final Color cardColor;
  final Color accentColor;
  final Color subTextColor;

  const AppTheme({
    required this.name,
    required this.bgColor,
    required this.textColor,
    required this.cardColor,
    required this.accentColor,
    required this.subTextColor,
  });
}

class ThemeManager {
  static final List<AppTheme> themes = [
    const AppTheme(
      name: 'Light Crisp',
      bgColor: Color(0xFFFDFDFD),
      textColor: Colors.black,
      cardColor: Colors.white,
      accentColor: Color(0xFFF83758),
      subTextColor: Color(0xFF757575),
    ),
    const AppTheme(
      name: 'Deep Slate',
      bgColor: Color(0xFF1E293B),
      textColor: Colors.white,
      cardColor: Color(0xFF334155),
      accentColor: Color(0xFF38BDF8),
      subTextColor: Color(0xFF94A3B8),
    ),
    const AppTheme(
      name: 'Soft Lavender',
      bgColor: Color(0xFFFAF5FF),
      textColor: Color(0xFF4A0E4E),
      cardColor: Color(0xFFF3E8FF),
      accentColor: Color(0xFFC084FC),
      subTextColor: Color(0xFF7E22CE),
    ),
    const AppTheme(
      name: 'Mint Clean',
      bgColor: Color(0xFFF0FDF4),
      textColor: Color(0xFF14532D),
      cardColor: Color(0xFFDCFCE7),
      accentColor: Color(0xFF16A34A),
      subTextColor: Color(0xFF15803D),
    ),
  ];

  static final ValueNotifier<AppTheme> currentTheme = ValueNotifier<AppTheme>(themes[0]);

  static void changeTheme(String themeName) {
    final theme = themes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => themes[0],
    );
    currentTheme.value = theme;
  }
}
