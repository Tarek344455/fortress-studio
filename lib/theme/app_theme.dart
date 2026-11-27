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
      colorScheme: ColorScheme.dark(
        background: obsidian,
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
          side: BorderSide(color: glassBorder, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: glassSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accentCyan, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentCyan,
          foregroundColor: obsidian,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary, fontFamily: 'Arabic'),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textPrimary, fontFamily: 'Arabic'),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary, fontFamily: 'Arabic'),
        bodyMedium: TextStyle(fontSize: 14, color: textSecondary, fontFamily: 'Arabic'),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary, fontFamily: 'Arabic'),
      ),
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: accentCyan.withValues(alpha: 0.3),
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

  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.bordered = true});

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

class StatusBadge extends StatelessWidget {
  final String status;
  final double fontSize;

  const StatusBadge({super.key, required this.status, this.fontSize = 12});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          fontFamily: 'Mono',
        ),
      ),
    );
  }
}
