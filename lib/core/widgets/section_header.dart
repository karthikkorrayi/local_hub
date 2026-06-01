import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/android_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w700,
            color: AndroidTheme.textTertiary, letterSpacing: 0.8,
          ),
        ),
        if (trailing != null) ...[const Spacer(), trailing!],
      ],
    );
  }
}