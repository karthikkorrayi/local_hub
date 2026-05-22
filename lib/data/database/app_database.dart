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

// ── Migration 1 → 2 ───────────────────────────────────────────────────────────
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

// ── Migration 2 → 3 ───────────────────────────────────────────────────────────
final migration2to3 = Migration(2, 3, (database) async {
  // Drop old flat Asset table
  await database.execute('DROP TABLE IF EXISTS Asset');

  // New Asset table with folderId and imagePath
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `Asset` (
      `id` TEXT NOT NULL,
      `folderId` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `type` TEXT NOT NULL,
      `notes` TEXT,
      `imagePath` TEXT,
      `tags` TEXT,
      `createdAt` INTEGER NOT NULL,
      `updatedAt` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');

  // New AssetFolder table
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `AssetFolder` (
      `id` TEXT NOT NULL,
      `name` TEXT NOT NULL,
      `icon` TEXT NOT NULL,
      `createdAt` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
});

@Database(
  version: 3,
  entities: [Job, WishlistItem, CalendarEvent, Asset, AssetFolder, DayEntry, WeekTodo],
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