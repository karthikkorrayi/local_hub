import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/job.dart';
import '../models/wishlist_item.dart';
import '../models/calendar_event.dart';
import '../models/asset.dart';
import '../models/asset_folder.dart';
import '../models/day_entry.dart';
import '../models/week_todo.dart';
import '../daos/job_dao.dart';
import '../daos/wishlist_dao.dart';
import '../daos/calendar_dao.dart';
import '../daos/asset_dao.dart';
import '../daos/asset_folder_dao.dart';
import '../daos/day_entry_dao.dart';
import '../daos/week_todo_dao.dart';

part 'app_database.g.dart';

Future<void> _safeAddColumn(
    sqflite.DatabaseExecutor db, String sql) async {
  try {
    await db.execute(sql);
  } catch (_) {}
}

final migration1to2 = Migration(1, 2, (database) async {
  await database.execute('DROP TABLE IF EXISTS CalendarEvent');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `CalendarEvent` (
      `id` TEXT NOT NULL, `title` TEXT NOT NULL, `description` TEXT,
      `date` TEXT NOT NULL, `startTime` TEXT, `endTime` TEXT,
      `category` TEXT NOT NULL, `linkedJobId` TEXT, `linkedJobTitle` TEXT,
      `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `DayEntry` (
      `id` TEXT NOT NULL, `date` TEXT NOT NULL,
      `mood` TEXT, `diary` TEXT, PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `WeekTodo` (
      `id` TEXT NOT NULL, `weekStart` TEXT NOT NULL,
      `title` TEXT NOT NULL, `isDone` INTEGER NOT NULL,
      `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`)
    )
  ''');
});

final migration2to3 = Migration(2, 3, (database) async {
  await database.execute('DROP TABLE IF EXISTS Asset');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `Asset` (
      `id` TEXT NOT NULL, `folderId` TEXT NOT NULL, `title` TEXT NOT NULL,
      `type` TEXT NOT NULL, `notes` TEXT, `imagePath` TEXT, `tags` TEXT,
      `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `AssetFolder` (
      `id` TEXT NOT NULL, `name` TEXT NOT NULL, `icon` TEXT NOT NULL,
      `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`)
    )
  ''');
});

final migration3to4 = Migration(3, 4, (database) async {
  await _safeAddColumn(database, 'ALTER TABLE Job ADD COLUMN resumePath TEXT');
  await _safeAddColumn(database, 'ALTER TABLE Job ADD COLUMN appliedAt INTEGER');
});

final migration4to5 = Migration(4, 5, (database) async {
  await _safeAddColumn(database, 'ALTER TABLE Job ADD COLUMN noteHistory TEXT');
  await _safeAddColumn(database, 'ALTER TABLE Job ADD COLUMN statusHistory TEXT');
  await _safeAddColumn(database, 'ALTER TABLE WishlistItem ADD COLUMN targetPurchaseAt INTEGER');
  await _safeAddColumn(database, 'ALTER TABLE WishlistItem ADD COLUMN purchasedAt INTEGER');
  await _safeAddColumn(database, 'ALTER TABLE CalendarEvent ADD COLUMN itemType TEXT');
  await _safeAddColumn(database, 'ALTER TABLE CalendarEvent ADD COLUMN contactInfo TEXT');
  await _safeAddColumn(database, 'ALTER TABLE CalendarEvent ADD COLUMN attachmentPath TEXT');
  await _safeAddColumn(database, 'ALTER TABLE CalendarEvent ADD COLUMN isDone INTEGER NOT NULL DEFAULT 0');
  await _safeAddColumn(database, 'ALTER TABLE Asset ADD COLUMN filePath TEXT');
  await _safeAddColumn(database, 'ALTER TABLE AssetFolder ADD COLUMN description TEXT');
});

final migration5to6 = Migration(5, 6, (database) async {
  await _safeAddColumn(database, 'ALTER TABLE AssetFolder ADD COLUMN parentId TEXT');
});

final migration6to7 = Migration(6, 7, (database) async {
  await _safeAddColumn(database, 'ALTER TABLE WishlistItem ADD COLUMN giftFor TEXT');
  await _safeAddColumn(database, 'ALTER TABLE WishlistItem ADD COLUMN giftDate INTEGER');
});

final migration7to8 = Migration(7, 8, (database) async {
  await _safeAddColumn(database, 'ALTER TABLE CalendarEvent ADD COLUMN birthDay INTEGER');
  await _safeAddColumn(database, 'ALTER TABLE CalendarEvent ADD COLUMN birthMonth INTEGER');
  await _safeAddColumn(database,
      'ALTER TABLE CalendarEvent ADD COLUMN isRecurring INTEGER NOT NULL DEFAULT 0');
});

@Database(
  version: 8,
  entities: [
    Job,
    WishlistItem,
    CalendarEvent,
    Asset,
    AssetFolder,
    DayEntry,
    WeekTodo,
  ],
)
abstract class AppDatabase extends FloorDatabase {
  JobDao get jobDao;
  WishlistDao get wishlistDao;
  CalendarDao get calendarDao;
  AssetDao get assetDao;
  AssetFolderDao get assetFolderDao;
  DayEntryDao get dayEntryDao;
  WeekTodoDao get weekTodoDao;
}