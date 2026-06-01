import 'package:flutter/material.dart';
import '../theme/android_theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding, this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AndroidTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AndroidTheme.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: onTap != null
            ? InkWell(onTap: onTap, child: _padded())
            : _padded(),
      ),
    );
  }

  Widget _padded() => padding != null
      ? Padding(padding: padding!, child: child)
      : child;
}