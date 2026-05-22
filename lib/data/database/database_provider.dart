import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await $FloorAppDatabase
      .databaseBuilder('local_hub.db')
      .addMigrations([migration1to2])
      .build();
  return database;
});

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

final dayEntryDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).requireValue.dayEntryDao;
});

final weekTodoDaoProvider = Provider((ref) {
  return ref.watch(databaseProvider).requireValue.weekTodoDao;
});