import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  static const _destinations = [
    (icon: Icons.work_outline,     label: 'Jobs',     path: '/jobs'),
    (icon: Icons.favorite_outline, label: 'Wishlist', path: '/wishlist'),
    (icon: Icons.calendar_today,   label: 'Calendar', path: '/calendar'),
    (icon: Icons.folder_outlined,  label: 'Assets',   path: '/assets'),
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

    if (isWide) {
      // macOS / tablet: left rail navigation
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
                        icon: Icon(d.icon),
                        label: Text(d.label),
                      ))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    // Android: bottom navigation bar
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selected,
        onDestinationSelected: (i) => context.go(_destinations[i].path),
        destinations: _destinations
            .map((d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ))
            .toList(),
      ),
    );
  }
}