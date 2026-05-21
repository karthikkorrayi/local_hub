import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../features/wishlist/wishlist_screen.dart';
import '../../features/calendar/calendar_screen.dart';
import '../../features/assets/assets_screen.dart';
import '../widgets/app_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/jobs',
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/jobs',
          builder: (context, state) => const JobsScreen(),
        ),
        GoRoute(
          path: '/wishlist',
          builder: (context, state) => const WishlistScreen(),
        ),
        GoRoute(
          path: '/calendar',
          builder: (context, state) => const CalendarScreen(),
        ),
        GoRoute(
          path: '/assets',
          builder: (context, state) => const AssetsScreen(),
        ),
      ],
    ),
  ],
);