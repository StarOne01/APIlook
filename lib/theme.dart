import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData getDarkTheme() {
    return ThemeData.dark().copyWith(
      useMaterial3: true,
      colorScheme: ColorScheme.dark(
        primary: Colors.blue[400]!,
        secondary: Colors.tealAccent[400]!,
        tertiary: Colors.deepPurple[300]!,
        surface: const Color(0xFF1E1E1E),
        background: const Color(0xFF121212),
        error: Colors.redAccent[400]!,
      ),
      cardTheme: CardTheme(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 16,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Inter',
          fontWeight: FontWeight.w600,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.blue[400]!,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  static const syntaxTheme = {
    'keyword': TextStyle(color: Color(0xFF569CD6)),
    'string': TextStyle(color: Color(0xFF6A9955)),
    'number': TextStyle(color: Color(0xFFB5CEA8)),
    'comment': TextStyle(color: Color(0xFF6A9955)),
    'punctuation': TextStyle(color: Color(0xFFD4D4D4)),
    'class': TextStyle(color: Color(0xFF4EC9B0)),
    'constant': TextStyle(color: Color(0xFF4FC1FF)),
  };
}
