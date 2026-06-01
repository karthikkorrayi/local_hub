import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/android_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.work_outline,      label: 'Jobs',     path: '/jobs'),
    (icon: Icons.favorite_outline,  label: 'Wishlist', path: '/wishlist'),
    (icon: Icons.calendar_today,    label: 'Calendar', path: '/calendar'),
    (icon: Icons.folder_outlined,   label: 'Assets',   path: '/assets'),
    (icon: Icons.settings_outlined, label: 'Settings', path: '/settings'),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _destinations.indexWhere((d) => location.startsWith(d.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final isAndroid = Platform.isAndroid;

    // macOS wide — navigation rail, no bottom bar
    if (isWide && !isAndroid) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              labelType: NavigationRailLabelType.all,
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].path),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon), label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Android — NO outer Scaffold wrapping.
    // Each screen provides its own Scaffold + FAB.
    // AppShell only injects the bottom nav bar via a Stack.
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 64,
          ),
          child: child,
        ),
        // Bottom nav bar pinned at bottom
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: AndroidTheme.divider, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: selected,
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].path),
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shadowColor: Colors.transparent,
              elevation: 0,
              height: 64,
              destinations: _destinations
                  .map((d) => NavigationDestination(
                        icon: Icon(d.icon), label: d.label))
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }
}