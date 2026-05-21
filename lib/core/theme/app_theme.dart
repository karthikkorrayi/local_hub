import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF1A73E8);
  static const Color surface = Color(0xFFF8F9FA);
  static const Color cardBackground = Colors.white;

  // Kanban status colors
  static const Color statusWishlist  = Color(0xFF9E9E9E);
  static const Color statusApplied   = Color(0xFF1A73E8);
  static const Color statusInterview = Color(0xFFF9A825);
  static const Color statusOffer     = Color(0xFF2E7D32);
  static const Color statusRejected  = Color(0xFFC62828);

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primary,
      surface: surface,
    ),
    cardTheme: const CardThemeData(
      color: cardBackground,
      elevation: 2,
      margin: EdgeInsets.zero,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A1A),
      elevation: 0,
      centerTitle: false,
    ),
  );

  static Color statusColor(String status) {
    switch (status) {
      case 'applied':    return statusApplied;
      case 'interview':  return statusInterview;
      case 'offer':      return statusOffer;
      case 'rejected':   return statusRejected;
      default:           return statusWishlist;
    }
  }
}