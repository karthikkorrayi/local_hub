import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

// A single shared instance of the database for the entire app lifetime.
// AsyncNotifierProvider ensures it's opened once and reused everywhere.
final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await $FloorAppDatabase
      .databaseBuilder('local_hub.db')
      .build();
  return database;
});

// Convenience DAO providers — screens import these, not the database directly.
final jobDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).requireValue.jobDao;
});

final wishlistDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).requireValue.wishlistDao;
});

final calendarDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).requireValue.calendarDao;
});

final assetDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).requireValue.assetDao;
});