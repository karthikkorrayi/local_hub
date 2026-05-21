import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;

import '../models/job.dart';
import '../models/wishlist_item.dart';
import '../models/calendar_event.dart';
import '../models/asset.dart';
import '../daos/job_dao.dart';
import '../daos/wishlist_dao.dart';
import '../daos/calendar_dao.dart';
import '../daos/asset_dao.dart';

part 'app_database.g.dart';

@Database(
  version: 1,
  entities: [Job, WishlistItem, CalendarEvent, Asset],
)
abstract class AppDatabase extends FloorDatabase {
  JobDao get jobDao;
  WishlistDao get wishlistDao;
  CalendarDao get calendarDao;
  AssetDao get assetDao;
}