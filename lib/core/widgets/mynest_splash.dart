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
  late final Animation<double> _modulesReveal;
  late final Animation<double> _modulesArrange;
  late final Animation<double> _title;
  late final Animation<double> _exit;
  bool _showSplash = true;

  static const _moduleItems = [
    (
      icon: Icons.work_outline,
      label: 'Jobs',
      color: AndroidTheme.jobsPrimary,
    ),
    (
      icon: Icons.favorite_outline,
      label: 'Wishlist',
      color: AndroidTheme.wishlistPrimary,
    ),
    (
      icon: Icons.calendar_month,
      label: 'Calendar',
      color: AndroidTheme.calendarPrimary,
    ),
    (
      icon: Icons.folder_outlined,
      label: 'Assets',
      color: Color(0xFFEAB308),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() => _showSplash = false);
        }
      })
      ..forward();

    _modulesReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.34, curve: Curves.easeOutCubic),
    );
    _modulesArrange = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.24, 0.66, curve: Curves.easeInOutCubic),
    );
    _title = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.64, 0.9, curve: Curves.easeOutCubic),
    );
    _exit = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.9, 1.0, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
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
              final splashBackground = theme.brightness == Brightness.dark
                  ? theme.scaffoldBackgroundColor
                  : Colors.white;
              return IgnorePointer(
                child: Opacity(
                  opacity: 1 - _exit.value,
                  child: ColoredBox(
                    color: splashBackground,
                    child: SafeArea(
                      child: Center(
                        child: DefaultTextStyle.merge(
                          style: const TextStyle(
                            decoration: TextDecoration.none,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _ModuleConstellation(
                                items: _moduleItems,
                                reveal: _modulesReveal.value,
                                arrange: _modulesArrange.value,
                                timeline: _controller.value,
                              ),
                              const SizedBox(height: 34),
                              _BrandLockup(progress: _title.value),
                            ],
                          ),
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

class _BrandLockup extends StatelessWidget {
  final double progress;
  const _BrandLockup({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final eased = progress.clamp(0.0, 1.0).toDouble();

    return Transform.translate(
      offset: Offset(0, 14 * (1 - eased)),
      child: Opacity(
        opacity: eased,
        child: Column(
          children: [
            Text(
              'MyNest',
              style: GoogleFonts.inter(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: theme.colorScheme.onSurface,
                decoration: TextDecoration.none,
                height: 1.02,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Everything important, beautifully organized',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.08,
                color: theme.colorScheme.onSurfaceVariant,
                decoration: TextDecoration.none,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleConstellation extends StatelessWidget {
  final double arrange;
  final List<({Color color, IconData icon, String label})> items;
  final double reveal;
  final double timeline;

  const _ModuleConstellation({
    required this.items,
    required this.reveal,
    required this.arrange,
    required this.timeline,
  });

  static const _startPosition = Alignment(0, 0.04);
  static const _endPositions = [
    Alignment(-0.72, -0.58),
    Alignment(0.72, -0.58),
    Alignment(-0.72, 0.58),
    Alignment(0.72, 0.58),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 246,
      height: 188,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var index = 0; index < items.length; index++)
            _PositionedModuleChip(
              arrange: arrange,
              end: _endPositions[index],
              index: index,
              item: items[index],
              reveal: reveal,
              start: _startPosition,
              timeline: timeline,
            ),
        ],
      ),
    );
  }
}

class _PositionedModuleChip extends StatelessWidget {
  final double arrange;
  final Alignment end;
  final int index;
  final ({Color color, IconData icon, String label}) item;
  final double reveal;
  final Alignment start;
  final double timeline;

  const _PositionedModuleChip({
    required this.arrange,
    required this.end,
    required this.index,
    required this.item,
    required this.reveal,
    required this.start,
    required this.timeline,
  });

  @override
  Widget build(BuildContext context) {
    final revealStart = index * 0.055;
    final revealProgress =
        ((timeline - revealStart) / 0.28).clamp(0.0, 1.0).toDouble();
    final easedReveal = Curves.easeOutCubic.transform(revealProgress);
    final position = Alignment.lerp(start, end, arrange) ?? end;
    final scale =
        0.74 + (0.26 * easedReveal) + (0.04 * reveal * (1 - arrange));

    return Align(
      alignment: position,
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: easedReveal,
          child: _ModuleChip(item: item),
        ),
      ),
    );
  }
}

class _ModuleChip extends StatelessWidget {
  final ({Color color, IconData icon, String label}) item;
  const _ModuleChip({required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 96,
      height: 76,
      decoration: BoxDecoration(
        color: item.color.withValues(alpha: isDark ? 0.13 : 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: item.color.withValues(alpha: isDark ? 0.34 : 0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: item.color.withValues(alpha: isDark ? 0.10 : 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.color, size: 25),
          const SizedBox(height: 7),
          Text(
            item.label,
            style: GoogleFonts.inter(
              color: theme.colorScheme.onSurface,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.05,
              decoration: TextDecoration.none,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}