import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/android_theme.dart';

class MyNestStartupSplash extends StatefulWidget {
  final Widget child;
  const MyNestStartupSplash({super.key, required this.child});

  @override
  State<MyNestStartupSplash> createState() => _MyNestStartupSplashState();
}

class _MyNestStartupSplashState extends State<MyNestStartupSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logo;
  late final Animation<double> _modules;
  late final Animation<double> _title;
  late final Animation<double> _exit;
  Timer? _timer;
  bool _showSplash = true;

  static const _moduleItems = [
    (icon: Icons.work_outline_rounded, label: 'Jobs', color: AndroidTheme.jobsPrimary),
    (icon: Icons.favorite_outline_rounded, label: 'Wishlist', color: AndroidTheme.wishlistPrimary),
    (icon: Icons.calendar_month_rounded, label: 'Calendar', color: AndroidTheme.calendarPrimary),
    (icon: Icons.folder_outlined, label: 'Assets', color: AndroidTheme.assetsPrimary),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..forward();
    _logo = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOutBack),
    );
    _modules = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.34, 0.68, curve: Curves.easeOutCubic),
    );
    _title = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.9, curve: Curves.easeOutCubic),
    );
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
    );
    _timer = Timer(const Duration(milliseconds: 3050), () {
      if (mounted) setState(() => _showSplash = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_showSplash)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;
              return IgnorePointer(
                child: Opacity(
                  opacity: 1 - _exit.value,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.scaffoldBackgroundColor,
                      gradient: RadialGradient(
                        center: Alignment.topCenter,
                        radius: 1.1,
                        colors: [
                          AndroidTheme.primary.withValues(alpha: isDark ? 0.16 : 0.12),
                          theme.scaffoldBackgroundColor,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Transform.scale(
                              scale: 0.78 + (_logo.value * 0.22),
                              child: Opacity(
                                opacity: _logo.value.clamp(0.0, 1.0).toDouble(),
                                child: _NestMark(isDark: isDark),
                              ),
                            ),
                            const SizedBox(height: 26),
                            Transform.scale(
                              scale: 0.86 + (_modules.value * 0.14),
                              child: Opacity(
                                opacity: _modules.value.clamp(0.0, 1.0).toDouble(),
                                child: _ModuleGrid(items: _moduleItems),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Transform.translate(
                              offset: Offset(0, 16 * (1 - _title.value)),
                              child: Opacity(
                                opacity: _title.value.clamp(0.0, 1.0).toDouble(),
                                child: Column(
                                  children: [
                                    Text(
                                      'MyNest',
                                      style: GoogleFonts.inter(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -1.1,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'Everything important in one personal space',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _NestMark extends StatelessWidget {
  final bool isDark;
  const _NestMark({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: AndroidTheme.primary.withValues(alpha: isDark ? 0.22 : 0.18),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.home_rounded, size: 48, color: AndroidTheme.primary),
          Positioned(
            bottom: 24,
            child: Container(
              width: 54,
              height: 16,
              decoration: BoxDecoration(
                border: Border.all(color: AndroidTheme.primary.withValues(alpha: 0.55), width: 3),
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final List<({Color color, IconData icon, String label})> items;
  const _ModuleGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 188,
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: items
            .map((item) => Container(
                  width: 86,
                  height: 72,
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: item.color.withValues(alpha: 0.35)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item.icon, color: item.color, size: 24),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}