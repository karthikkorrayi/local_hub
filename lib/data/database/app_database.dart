import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/job.dart';
import '../models/wishlist_item.dart';
import '../models/calendar_event.dart';
import '../models/asset.dart';
import '../models/day_entry.dart';
import '../models/week_todo.dart';
import '../daos/job_dao.dart';
import '../daos/wishlist_dao.dart';
import '../daos/calendar_dao.dart';
import '../daos/asset_dao.dart';
import '../daos/day_entry_dao.dart';
import '../daos/week_todo_dao.dart';

part 'app_database.g.dart';

final migration1to2 = Migration(1, 2, (database) async {
  await database.execute('DROP TABLE IF EXISTS CalendarEvent');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `CalendarEvent` (
      `id` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `description` TEXT,
      `date` TEXT NOT NULL,
      `startTime` TEXT,
      `endTime` TEXT,
      `category` TEXT NOT NULL,
      `linkedJobId` TEXT,
      `linkedJobTitle` TEXT,
      `createdAt` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `DayEntry` (
      `id` TEXT NOT NULL,
      `date` TEXT NOT NULL,
      `mood` TEXT,
      `diary` TEXT,
      PRIMARY KEY (`id`)
    )
  ''');
  await database.execute('''
    CREATE TABLE IF NOT EXISTS `WeekTodo` (
      `id` TEXT NOT NULL,
      `weekStart` TEXT NOT NULL,
      `title` TEXT NOT NULL,
      `isDone` INTEGER NOT NULL,
      `createdAt` INTEGER NOT NULL,
      PRIMARY KEY (`id`)
    )
  ''');
});

@Database(
  version: 2,
  entities: [Job, WishlistItem, CalendarEvent, Asset, DayEntry, WeekTodo],
)
abstract class AppDatabase extends FloorDatabase {
  JobDao get jobDao;
  WishlistDao get wishlistDao;
  CalendarDao get calendarDao;
  AssetDao get assetDao;
  DayEntryDao get dayEntryDao;
  WeekTodoDao get weekTodoDao;
}