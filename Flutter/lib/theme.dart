import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final theme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF5B8B4B), // 메인 그린
    brightness: Brightness.light,
  ),
  scaffoldBackgroundColor: Colors.white,
  textTheme: GoogleFonts.interTextTheme().copyWith(
    titleLarge: const TextStyle(fontWeight: FontWeight.w600),
  ),
  useMaterial3: true,
);
