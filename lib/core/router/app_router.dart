import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/jobs/jobs_screen.dart';
import '../../data/models/job.dart';
import '../../data/models/wishlist_item.dart';
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
        GoRoute(path: '/jobs/:id', builder: (_, state) => JobDetailsScreen(
          jobId: state.pathParameters['id']!,
          initialJob: state.extra is Job ? state.extra as Job : null,
        )),
        GoRoute(path: '/wishlist', builder: (_, __) => const WishlistScreen()),
        GoRoute(path: '/wishlist/:id', builder: (_, state) => WishlistDetailsScreen(
          itemId: state.pathParameters['id']!,
          initialItem: state.extra is WishlistItem ? state.extra as WishlistItem : null,
        )),
        GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
        GoRoute(path: '/assets',   builder: (_, __) => const AssetsScreen()),
        GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
      ],
    ),
  ],
);