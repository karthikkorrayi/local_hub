import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

final databaseProvider = FutureProvider<AppDatabase>((ref) async {
  final database = await $FloorAppDatabase
      .databaseBuilder('local_hub.db')
      .addMigrations([
        migration1to2,
        migration2to3,
        migration3to4,
        migration4to5,
        migration5to6,
        migration6to7,
        migration7to8, // birthDay, birthMonth, isRecurring
      ])
      .build();
  return database;
});

final jobDaoProvider         = Provider((ref) => ref.watch(databaseProvider).requireValue.jobDao);
final wishlistDaoProvider    = Provider((ref) => ref.watch(databaseProvider).requireValue.wishlistDao);
final calendarDaoProvider    = Provider((ref) => ref.watch(databaseProvider).requireValue.calendarDao);
final assetDaoProvider       = Provider((ref) => ref.watch(databaseProvider).requireValue.assetDao);
final assetFolderDaoProvider = Provider((ref) => ref.watch(databaseProvider).requireValue.assetFolderDao);
final dayEntryDaoProvider    = Provider((ref) => ref.watch(databaseProvider).requireValue.dayEntryDao);
final weekTodoDaoProvider    = Provider((ref) => ref.watch(databaseProvider).requireValue.weekTodoDao);