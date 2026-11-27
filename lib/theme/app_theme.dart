import 'package:flutter/material.dart';

class AppTheme {
  static const Color obsidian = Color(0xFF0B0C10);
  static const Color glassSurface = Color(0xFF1A1B26);
  static const Color glassBorder = Color(0xFF2D2E3E);
  static const Color accentCyan = Color(0xFF00F0FF);
  static const Color accentGold = Color(0xFFFFD700);
  static const Color accentGreen = Color(0xFF00FF88);
  static const Color accentAmber = Color(0xFFFFB800);
  static const Color accentRed = Color(0xFFFF4444);
  static const Color textPrimary = Color(0xFFE4E4E7);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData darkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: obsidian,
      colorScheme: const ColorScheme.dark(
        surface: glassSurface,
        onSurface: textPrimary,
        primary: accentCyan,
        secondary: accentGold,
        error: accentRed,
        onError: Colors.white,
      ),
      cardTheme: CardTheme(
        color: glassSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: accentCyan, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: obsidian,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, fontFamily: 'Arabic'),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, fontFamily: 'Arabic'),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary, fontFamily: 'Arabic'),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary, fontFamily: 'Arabic'),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, fontFamily: 'Arabic'),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: accentCyan.withOpacity(0.3),
      ),
    );
  }

  static Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pass':
        return accentGreen;
      case 'partial':
        return accentAmber;
      case 'fail':
        return accentRed;
      case 'active':
        return accentCyan;
      default:
        return textMuted;
    }
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool bordered;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.bordered = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: bordered ? Border.all(color: AppTheme.glassBorder, width: 1) : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}
