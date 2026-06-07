import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/backup/backup_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/android_theme.dart';
import 'core/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyNestApp()));
}

class MyNestApp extends ConsumerWidget {
  const MyNestApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appThemeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'MyNest',
      // Light theme — always provided
      theme: AndroidTheme.theme,
      // Dark theme — always provided
      darkTheme: AndroidTheme.darkTheme,
      // Which to use — driven by user preference
      themeMode: appThemeMode.flutterMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) =>
          AppLifecycleObserver(child: child ?? const SizedBox()),
    );
  }
}

class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  const AppLifecycleObserver({super.key, required this.child});

  @override
  ConsumerState<AppLifecycleObserver> createState() =>
      _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      ref.read(backupProvider.notifier).backup();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}