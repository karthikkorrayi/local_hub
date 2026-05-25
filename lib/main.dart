import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/backup/backup_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Temporary: find DB path
  // final support = await getApplicationSupportDirectory();
  // final documents = await getApplicationDocumentsDirectory();
  // final library = await getLibraryDirectory();
  
  // debugPrint('=== SUPPORT: ${support.path}');
  // debugPrint('=== DOCUMENTS: ${documents.path}');
  // debugPrint('=== LIBRARY: ${library.path}');
  // debugPrint('=== SUPPORT/local_hub.db exists: ${await File(p.join(support.path, 'local_hub.db')).exists()}');
  // debugPrint('=== DOCUMENTS/local_hub.db exists: ${await File(p.join(documents.path, 'local_hub.db')).exists()}');
  // debugPrint('=== LIBRARY/local_hub.db exists: ${await File(p.join(library.path, 'local_hub.db')).exists()}');
  
  runApp(const ProviderScope(child: LocalHubApp()));
}

class LocalHubApp extends StatelessWidget {
  const LocalHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Local Hub',
      theme: AppTheme.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AppLifecycleObserver(child: child ?? const SizedBox()),
    );
  }
}

// Watches app lifecycle and triggers auto-backup on pause/detach
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
      // Fire and forget — don't await, app may be closing
      ref.read(backupProvider.notifier).backup();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}