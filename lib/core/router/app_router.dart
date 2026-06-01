import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/assets/assets_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/jobs',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/jobs',     builder: (_, __) => const JobsScreen()),
        GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/assets',   builder: (_, __) => const AssetsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);