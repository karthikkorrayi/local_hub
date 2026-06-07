import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AndroidTheme {
  // ── Light palette ────────────────────────────────────────────────────────────
  static const Color primary       = Color(0xFF1EC86A);
  static const Color primaryLight  = Color(0xFFE8F8F0);
  static const Color surface       = Color(0xFFF2F4F7);
  static const Color card          = Color(0xFFFFFFFF);
  static const Color textPrimary   = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary  = Color(0xFF9CA3AF);
  static const Color divider       = Color(0xFFE5E7EB);

  // ── Dark palette ─────────────────────────────────────────────────────────────
  static const Color darkSurface       = Color(0xFF0F1117);
  static const Color darkCard          = Color(0xFF1C1F2A);
  static const Color darkTextPrimary   = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary  = Color(0xFF64748B);
  static const Color darkDivider       = Color(0xFF2D3147);

  // ── Module colors (same in both modes, adjusted via opacity for dark) ────────
  static const Color jobsPrimary      = Color(0xFFF97316);
  static const Color jobsPrimaryLight = Color(0xFFFFF7ED);
  static const Color jobsDark         = Color(0xFF2D1A0A); // dark bg tint

  static const Color wishlistPrimary      = Color(0xFFEF4444);
  static const Color wishlistPrimaryLight = Color(0xFFFEF2F2);
  static const Color wishlistDark         = Color(0xFF2D0A0A);

  static const Color calendarPrimary      = Color(0xFF3B82F6);
  static const Color calendarPrimaryLight = Color(0xFFEFF6FF);
  static const Color calendarDark         = Color(0xFF0A1628);

  static const Color assetsPrimary      = Color(0xFFD97706);
  static const Color assetsPrimaryLight = Color(0xFFFFFBEB);
  static const Color assetsDark         = Color(0xFF2A1A00);

  // ── Light theme ───────────────────────────────────────────────────────────────
  static ThemeData get theme => _build(dark: false);

  // ── Dark theme ────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme => _build(dark: true);

  static ThemeData _build({required bool dark}) {
    final bg   = dark ? darkSurface : surface;
    final crd  = dark ? darkCard    : card;
    final tp   = dark ? darkTextPrimary   : textPrimary;
    final ts   = dark ? darkTextSecondary : textSecondary;
    final tt   = dark ? darkTextTertiary  : textTertiary;
    final div  = dark ? darkDivider       : divider;

    return ThemeData(
      useMaterial3: true,
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: dark ? Brightness.dark : Brightness.light,
        surface: bg,
        primary: primary,
        onPrimary: Colors.white,
      ).copyWith(
        surface: bg,
        onSurface: tp,
        surfaceContainerHighest: crd,
        onSurfaceVariant: ts,
        outline: div,
        outlineVariant: div,
        primaryContainer: dark ? primary.withValues(alpha: 0.18) : primaryLight,
        onPrimaryContainer: dark ? const Color(0xFFB9F6D0) : const Color(0xFF075E2F),
        error: dark ? const Color(0xFFF87171) : const Color(0xFFB42318),
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.interTextTheme().apply(
        bodyColor: tp, displayColor: tp),
      appBarTheme: AppBarTheme(
        backgroundColor: crd,
        foregroundColor: tp,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20, fontWeight: FontWeight.w700,
          color: tp, letterSpacing: -0.3),
      ),
      cardTheme: CardThemeData(
        color: crd, elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: div, width: 1)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: crd,
        indicatorColor: primary.withValues(alpha: dark ? 0.2 : 0.12),
        height: 64, elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return GoogleFonts.inter(
            fontSize: 11,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            color: sel ? primary : tt);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final sel = states.contains(WidgetState.selected);
          return IconThemeData(color: sel ? primary : tt, size: 22);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: dark ? const Color(0xFF202431) : const Color(0xFFFFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: div)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: div)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: primary, width: 1.5)),
        labelStyle: GoogleFonts.inter(color: ts, fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: GoogleFonts.inter(color: tt, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
          elevation: 0)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600))),
      chipTheme: ChipThemeData(
        backgroundColor: crd,
        selectedColor: dark ? primary.withValues(alpha: 0.18) : primaryLight,
        labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: tp),
        secondaryLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
        side: BorderSide(color: div),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: true, checkmarkColor: primary),
      dividerTheme: DividerThemeData(color: div, thickness: 1, space: 1),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: crd,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        dragHandleColor: div,
        dragHandleSize: const Size(40, 4),
        showDragHandle: true),
      dialogTheme: DialogThemeData(
        backgroundColor: crd,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: tp),
        contentTextStyle: GoogleFonts.inter(fontSize: 14, color: ts, height: 1.5)),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? primary : Colors.white),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected)
                ? primary.withValues(alpha: 0.3) : div)),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: tp, iconColor: ts),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: dark ? const Color(0xFF252A38) : const Color(0xFF111827),
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        foregroundColor: Colors.white, elevation: 3),
      popupMenuTheme: PopupMenuThemeData(
        color: crd,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4),
    );
  }
}