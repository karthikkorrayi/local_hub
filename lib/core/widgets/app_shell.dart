import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/android_theme.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  // Icons matched to what the device renders (verified from screenshots)
  static const _destinations = [
    (icon: Icons.work_outline,          label: 'Jobs',     path: '/jobs',     color: AndroidTheme.jobsPrimary,      light: AndroidTheme.jobsPrimaryLight),
    (icon: Icons.favorite_outline,      label: 'Wishlist', path: '/wishlist', color: AndroidTheme.wishlistPrimary,  light: AndroidTheme.wishlistPrimaryLight),
    (icon: Icons.calendar_month,        label: 'Calendar', path: '/calendar', color: AndroidTheme.calendarPrimary,  light: AndroidTheme.calendarPrimaryLight),
    (icon: Icons.folder_outlined,       label: 'Assets',   path: '/assets',   color: AndroidTheme.assetsPrimary,    light: AndroidTheme.assetsPrimaryLight),
    (icon: Icons.settings_outlined,     label: 'Settings', path: '/settings', color: AndroidTheme.primary,          light: AndroidTheme.primaryLight),
  ];

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx = _destinations.indexWhere((d) => location.startsWith(d.path));
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedIndex(context);
    final activeColor = _destinations[selected].color;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeLight = isDark
        ? activeColor.withValues(alpha: 0.18)
        : _destinations[selected].light;
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final isAndroid = Platform.isAndroid;

    if (isWide && !isAndroid) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: selected,
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: IconThemeData(color: activeColor),
              selectedLabelTextStyle: TextStyle(
                  color: activeColor, fontWeight: FontWeight.w600),
              indicatorColor: activeLight,
              onDestinationSelected: (i) =>
                  context.go(_destinations[i].path),
              destinations: _destinations
                  .map((d) => NavigationRailDestination(
                        icon: Icon(d.icon),
                        label: Text(d.label)))
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: child),
          ],
        ),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 64,
          ),
          child: child,
        ),
        Positioned(
          left: 0, right: 0, bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              border: Border(
                  top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Theme(
              // Override NavigationBar theme with the active module color
              data: Theme.of(context).copyWith(
                navigationBarTheme: NavigationBarThemeData(
                  backgroundColor: Theme.of(context).cardTheme.color,
                  indicatorColor: activeLight,
                  height: 64,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  labelTextStyle:
                      WidgetStateProperty.resolveWith((states) {
                    final isSelected =
                        states.contains(WidgetState.selected);
                    return TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected
                          ? activeColor
                          : Theme.of(context).hintColor,
                    );
                  }),
                  iconTheme:
                      WidgetStateProperty.resolveWith((states) {
                    final isSelected =
                        states.contains(WidgetState.selected);
                    return IconThemeData(
                      color: isSelected
                          ? activeColor
                          : Theme.of(context).hintColor,
                      size: 22,
                    );
                  }),
                ),
              ),
              child: NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (i) =>
                    context.go(_destinations[i].path),
                backgroundColor: Theme.of(context).cardTheme.color,
                surfaceTintColor: Colors.transparent,
                shadowColor: Colors.transparent,
                elevation: 0,
                height: 64,
                destinations: _destinations
                    .map((d) => NavigationDestination(
                          icon: Icon(d.icon),
                          label: d.label))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}