// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(
      path,
      _migrations,
      _callback,
    );
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  JobDao? _jobDaoInstance;

  WishlistDao? _wishlistDaoInstance;

  CalendarDao? _calendarDaoInstance;

  AssetDao? _assetDaoInstance;

  AssetFolderDao? _assetFolderDaoInstance;

  DayEntryDao? _dayEntryDaoInstance;

  WeekTodoDao? _weekTodoDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 6,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
            database, startVersion, endVersion, migrations);

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Job` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `company` TEXT NOT NULL, `status` TEXT NOT NULL, `notes` TEXT, `url` TEXT, `resumePath` TEXT, `appliedAt` INTEGER, `noteHistory` TEXT, `statusHistory` TEXT, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WishlistItem` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `price` REAL, `imageUrl` TEXT, `category` TEXT, `productUrl` TEXT, `targetPurchaseAt` INTEGER, `isPurchased` INTEGER NOT NULL, `purchasedAt` INTEGER, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `CalendarEvent` (`id` TEXT NOT NULL, `title` TEXT NOT NULL, `description` TEXT, `date` TEXT NOT NULL, `startTime` TEXT, `endTime` TEXT, `category` TEXT NOT NULL, `itemType` TEXT, `contactInfo` TEXT, `attachmentPath` TEXT, `isDone` INTEGER NOT NULL, `linkedJobId` TEXT, `linkedJobTitle` TEXT, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `Asset` (`id` TEXT NOT NULL, `folderId` TEXT NOT NULL, `title` TEXT NOT NULL, `type` TEXT NOT NULL, `notes` TEXT, `imagePath` TEXT, `tags` TEXT, `filePath` TEXT, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `AssetFolder` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `icon` TEXT NOT NULL, `description` TEXT, `parentId` TEXT, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `DayEntry` (`id` TEXT NOT NULL, `date` TEXT NOT NULL, `mood` TEXT, `diary` TEXT, PRIMARY KEY (`id`))');
        await database.execute(
            'CREATE TABLE IF NOT EXISTS `WeekTodo` (`id` TEXT NOT NULL, `weekStart` TEXT NOT NULL, `title` TEXT NOT NULL, `isDone` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY (`id`))');

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  JobDao get jobDao {
    return _jobDaoInstance ??= _$JobDao(database, changeListener);
  }

  @override
  WishlistDao get wishlistDao {
    return _wishlistDaoInstance ??= _$WishlistDao(database, changeListener);
  }

  @override
  CalendarDao get calendarDao {
    return _calendarDaoInstance ??= _$CalendarDao(database, changeListener);
  }

  @override
  AssetDao get assetDao {
    return _assetDaoInstance ??= _$AssetDao(database, changeListener);
  }

  @override
  AssetFolderDao get assetFolderDao {
    return _assetFolderDaoInstance ??=
        _$AssetFolderDao(database, changeListener);
  }

  @override
  DayEntryDao get dayEntryDao {
    return _dayEntryDaoInstance ??= _$DayEntryDao(database, changeListener);
  }

  @override
  WeekTodoDao get weekTodoDao {
    return _weekTodoDaoInstance ??= _$WeekTodoDao(database, changeListener);
  }
}

class _$JobDao extends JobDao {
  _$JobDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _jobInsertionAdapter = InsertionAdapter(
            database,
            'Job',
            (Job item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'company': item.company,
                  'status': item.status,
                  'notes': item.notes,
                  'url': item.url,
                  'resumePath': item.resumePath,
                  'appliedAt': item.appliedAt,
                  'noteHistory': item.noteHistory,
                  'statusHistory': item.statusHistory,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                }),
        _jobUpdateAdapter = UpdateAdapter(
            database,
            'Job',
            ['id'],
            (Job item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'company': item.company,
                  'status': item.status,
                  'notes': item.notes,
                  'url': item.url,
                  'resumePath': item.resumePath,
                  'appliedAt': item.appliedAt,
                  'noteHistory': item.noteHistory,
                  'statusHistory': item.statusHistory,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                }),
        _jobDeletionAdapter = DeletionAdapter(
            database,
            'Job',
            ['id'],
            (Job item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'company': item.company,
                  'status': item.status,
                  'notes': item.notes,
                  'url': item.url,
                  'resumePath': item.resumePath,
                  'appliedAt': item.appliedAt,
                  'noteHistory': item.noteHistory,
                  'statusHistory': item.statusHistory,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Job> _jobInsertionAdapter;

  final UpdateAdapter<Job> _jobUpdateAdapter;

  final DeletionAdapter<Job> _jobDeletionAdapter;

  @override
  Future<List<Job>> getAllJobs() async {
    return _queryAdapter.queryList('SELECT * FROM Job ORDER BY updatedAt DESC',
        mapper: (Map<String, Object?> row) => Job(
            id: row['id'] as String,
            title: row['title'] as String,
            company: row['company'] as String,
            status: row['status'] as String,
            notes: row['notes'] as String?,
            url: row['url'] as String?,
            resumePath: row['resumePath'] as String?,
            appliedAt: row['appliedAt'] as int?,
            noteHistory: row['noteHistory'] as String?,
            statusHistory: row['statusHistory'] as String?,
            createdAt: row['createdAt'] as int,
            updatedAt: row['updatedAt'] as int));
  }

  @override
  Future<List<Job>> getJobsByStatus(String status) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Job WHERE status = ?1 ORDER BY updatedAt DESC',
        mapper: (Map<String, Object?> row) => Job(
            id: row['id'] as String,
            title: row['title'] as String,
            company: row['company'] as String,
            status: row['status'] as String,
            notes: row['notes'] as String?,
            url: row['url'] as String?,
            resumePath: row['resumePath'] as String?,
            appliedAt: row['appliedAt'] as int?,
            noteHistory: row['noteHistory'] as String?,
            statusHistory: row['statusHistory'] as String?,
            createdAt: row['createdAt'] as int,
            updatedAt: row['updatedAt'] as int),
        arguments: [status]);
  }

  @override
  Future<Job?> getJobById(String id) async {
    return _queryAdapter.query('SELECT * FROM Job WHERE id = ?1',
        mapper: (Map<String, Object?> row) => Job(
            id: row['id'] as String,
            title: row['title'] as String,
            company: row['company'] as String,
            status: row['status'] as String,
            notes: row['notes'] as String?,
            url: row['url'] as String?,
            resumePath: row['resumePath'] as String?,
            appliedAt: row['appliedAt'] as int?,
            noteHistory: row['noteHistory'] as String?,
            statusHistory: row['statusHistory'] as String?,
            createdAt: row['createdAt'] as int,
            updatedAt: row['updatedAt'] as int),
        arguments: [id]);
  }

  @override
  Future<void> insertJob(Job job) async {
    await _jobInsertionAdapter.insert(job, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateJob(Job job) async {
    await _jobUpdateAdapter.update(job, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteJob(Job job) async {
    await _jobDeletionAdapter.delete(job);
  }
}

class _$WishlistDao extends WishlistDao {
  _$WishlistDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _wishlistItemInsertionAdapter = InsertionAdapter(
            database,
            'WishlistItem',
            (WishlistItem item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'price': item.price,
                  'imageUrl': item.imageUrl,
                  'category': item.category,
                  'productUrl': item.productUrl,
                  'targetPurchaseAt': item.targetPurchaseAt,
                  'isPurchased': item.isPurchased ? 1 : 0,
                  'purchasedAt': item.purchasedAt,
                  'createdAt': item.createdAt
                }),
        _wishlistItemUpdateAdapter = UpdateAdapter(
            database,
            'WishlistItem',
            ['id'],
            (WishlistItem item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'price': item.price,
                  'imageUrl': item.imageUrl,
                  'category': item.category,
                  'productUrl': item.productUrl,
                  'targetPurchaseAt': item.targetPurchaseAt,
                  'isPurchased': item.isPurchased ? 1 : 0,
                  'purchasedAt': item.purchasedAt,
                  'createdAt': item.createdAt
                }),
        _wishlistItemDeletionAdapter = DeletionAdapter(
            database,
            'WishlistItem',
            ['id'],
            (WishlistItem item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'price': item.price,
                  'imageUrl': item.imageUrl,
                  'category': item.category,
                  'productUrl': item.productUrl,
                  'targetPurchaseAt': item.targetPurchaseAt,
                  'isPurchased': item.isPurchased ? 1 : 0,
                  'purchasedAt': item.purchasedAt,
                  'createdAt': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WishlistItem> _wishlistItemInsertionAdapter;

  final UpdateAdapter<WishlistItem> _wishlistItemUpdateAdapter;

  final DeletionAdapter<WishlistItem> _wishlistItemDeletionAdapter;

  @override
  Future<List<WishlistItem>> getAllItems() async {
    return _queryAdapter.queryList(
        'SELECT * FROM WishlistItem ORDER BY createdAt DESC',
        mapper: (Map<String, Object?> row) => WishlistItem(
            id: row['id'] as String,
            name: row['name'] as String,
            price: row['price'] as double?,
            imageUrl: row['imageUrl'] as String?,
            category: row['category'] as String?,
            productUrl: row['productUrl'] as String?,
            targetPurchaseAt: row['targetPurchaseAt'] as int?,
            isPurchased: (row['isPurchased'] as int) != 0,
            purchasedAt: row['purchasedAt'] as int?,
            createdAt: row['createdAt'] as int));
  }

  @override
  Future<List<WishlistItem>> getItemsByPurchased(bool purchased) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WishlistItem WHERE isPurchased = ?1',
        mapper: (Map<String, Object?> row) => WishlistItem(
            id: row['id'] as String,
            name: row['name'] as String,
            price: row['price'] as double?,
            imageUrl: row['imageUrl'] as String?,
            category: row['category'] as String?,
            productUrl: row['productUrl'] as String?,
            targetPurchaseAt: row['targetPurchaseAt'] as int?,
            isPurchased: (row['isPurchased'] as int) != 0,
            purchasedAt: row['purchasedAt'] as int?,
            createdAt: row['createdAt'] as int),
        arguments: [purchased ? 1 : 0]);
  }

  @override
  Future<WishlistItem?> getItemById(String id) async {
    return _queryAdapter.query('SELECT * FROM WishlistItem WHERE id = ?1',
        mapper: (Map<String, Object?> row) => WishlistItem(
            id: row['id'] as String,
            name: row['name'] as String,
            price: row['price'] as double?,
            imageUrl: row['imageUrl'] as String?,
            category: row['category'] as String?,
            productUrl: row['productUrl'] as String?,
            targetPurchaseAt: row['targetPurchaseAt'] as int?,
            isPurchased: (row['isPurchased'] as int) != 0,
            purchasedAt: row['purchasedAt'] as int?,
            createdAt: row['createdAt'] as int),
        arguments: [id]);
  }

  @override
  Future<void> insertItem(WishlistItem item) async {
    await _wishlistItemInsertionAdapter.insert(item, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateItem(WishlistItem item) async {
    await _wishlistItemUpdateAdapter.update(item, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteItem(WishlistItem item) async {
    await _wishlistItemDeletionAdapter.delete(item);
  }
}

class _$CalendarDao extends CalendarDao {
  _$CalendarDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _calendarEventInsertionAdapter = InsertionAdapter(
            database,
            'CalendarEvent',
            (CalendarEvent item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'description': item.description,
                  'date': item.date,
                  'startTime': item.startTime,
                  'endTime': item.endTime,
                  'category': item.category,
                  'itemType': item.itemType,
                  'contactInfo': item.contactInfo,
                  'attachmentPath': item.attachmentPath,
                  'isDone': item.isDone ? 1 : 0,
                  'linkedJobId': item.linkedJobId,
                  'linkedJobTitle': item.linkedJobTitle,
                  'createdAt': item.createdAt
                }),
        _calendarEventUpdateAdapter = UpdateAdapter(
            database,
            'CalendarEvent',
            ['id'],
            (CalendarEvent item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'description': item.description,
                  'date': item.date,
                  'startTime': item.startTime,
                  'endTime': item.endTime,
                  'category': item.category,
                  'itemType': item.itemType,
                  'contactInfo': item.contactInfo,
                  'attachmentPath': item.attachmentPath,
                  'isDone': item.isDone ? 1 : 0,
                  'linkedJobId': item.linkedJobId,
                  'linkedJobTitle': item.linkedJobTitle,
                  'createdAt': item.createdAt
                }),
        _calendarEventDeletionAdapter = DeletionAdapter(
            database,
            'CalendarEvent',
            ['id'],
            (CalendarEvent item) => <String, Object?>{
                  'id': item.id,
                  'title': item.title,
                  'description': item.description,
                  'date': item.date,
                  'startTime': item.startTime,
                  'endTime': item.endTime,
                  'category': item.category,
                  'itemType': item.itemType,
                  'contactInfo': item.contactInfo,
                  'attachmentPath': item.attachmentPath,
                  'isDone': item.isDone ? 1 : 0,
                  'linkedJobId': item.linkedJobId,
                  'linkedJobTitle': item.linkedJobTitle,
                  'createdAt': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<CalendarEvent> _calendarEventInsertionAdapter;

  final UpdateAdapter<CalendarEvent> _calendarEventUpdateAdapter;

  final DeletionAdapter<CalendarEvent> _calendarEventDeletionAdapter;

  @override
  Future<List<CalendarEvent>> getEventsForDate(String date) async {
    return _queryAdapter.queryList(
        'SELECT * FROM CalendarEvent WHERE date = ?1 ORDER BY startTime ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(
            id: row['id'] as String,
            title: row['title'] as String,
            description: row['description'] as String?,
            date: row['date'] as String,
            startTime: row['startTime'] as String?,
            endTime: row['endTime'] as String?,
            category: row['category'] as String,
            itemType: row['itemType'] as String?,
            contactInfo: row['contactInfo'] as String?,
            attachmentPath: row['attachmentPath'] as String?,
            isDone: (row['isDone'] as int) != 0,
            linkedJobId: row['linkedJobId'] as String?,
            linkedJobTitle: row['linkedJobTitle'] as String?,
            createdAt: row['createdAt'] as int),
        arguments: [date]);
  }

  @override
  Future<List<CalendarEvent>> getEventsInRange(
    String from,
    String to,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM CalendarEvent WHERE date >= ?1 AND date <= ?2 ORDER BY date ASC, startTime ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(id: row['id'] as String, title: row['title'] as String, description: row['description'] as String?, date: row['date'] as String, startTime: row['startTime'] as String?, endTime: row['endTime'] as String?, category: row['category'] as String, itemType: row['itemType'] as String?, contactInfo: row['contactInfo'] as String?, attachmentPath: row['attachmentPath'] as String?, isDone: (row['isDone'] as int) != 0, linkedJobId: row['linkedJobId'] as String?, linkedJobTitle: row['linkedJobTitle'] as String?, createdAt: row['createdAt'] as int),
        arguments: [from, to]);
  }

  @override
  Future<List<CalendarEvent>> getEventsForJob(String jobId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM CalendarEvent WHERE linkedJobId = ?1 ORDER BY date ASC',
        mapper: (Map<String, Object?> row) => CalendarEvent(
            id: row['id'] as String,
            title: row['title'] as String,
            description: row['description'] as String?,
            date: row['date'] as String,
            startTime: row['startTime'] as String?,
            endTime: row['endTime'] as String?,
            category: row['category'] as String,
            itemType: row['itemType'] as String?,
            contactInfo: row['contactInfo'] as String?,
            attachmentPath: row['attachmentPath'] as String?,
            isDone: (row['isDone'] as int) != 0,
            linkedJobId: row['linkedJobId'] as String?,
            linkedJobTitle: row['linkedJobTitle'] as String?,
            createdAt: row['createdAt'] as int),
        arguments: [jobId]);
  }

  @override
  Future<void> insertEvent(CalendarEvent event) async {
    await _calendarEventInsertionAdapter.insert(
        event, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateEvent(CalendarEvent event) async {
    await _calendarEventUpdateAdapter.update(event, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteEvent(CalendarEvent event) async {
    await _calendarEventDeletionAdapter.delete(event);
  }
}

class _$AssetDao extends AssetDao {
  _$AssetDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _assetInsertionAdapter = InsertionAdapter(
            database,
            'Asset',
            (Asset item) => <String, Object?>{
                  'id': item.id,
                  'folderId': item.folderId,
                  'title': item.title,
                  'type': item.type,
                  'notes': item.notes,
                  'imagePath': item.imagePath,
                  'tags': item.tags,
                  'filePath': item.filePath,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                }),
        _assetUpdateAdapter = UpdateAdapter(
            database,
            'Asset',
            ['id'],
            (Asset item) => <String, Object?>{
                  'id': item.id,
                  'folderId': item.folderId,
                  'title': item.title,
                  'type': item.type,
                  'notes': item.notes,
                  'imagePath': item.imagePath,
                  'tags': item.tags,
                  'filePath': item.filePath,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                }),
        _assetDeletionAdapter = DeletionAdapter(
            database,
            'Asset',
            ['id'],
            (Asset item) => <String, Object?>{
                  'id': item.id,
                  'folderId': item.folderId,
                  'title': item.title,
                  'type': item.type,
                  'notes': item.notes,
                  'imagePath': item.imagePath,
                  'tags': item.tags,
                  'filePath': item.filePath,
                  'createdAt': item.createdAt,
                  'updatedAt': item.updatedAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Asset> _assetInsertionAdapter;

  final UpdateAdapter<Asset> _assetUpdateAdapter;

  final DeletionAdapter<Asset> _assetDeletionAdapter;

  @override
  Future<List<Asset>> getAssetsByFolder(String folderId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Asset WHERE folderId = ?1 ORDER BY updatedAt DESC',
        mapper: (Map<String, Object?> row) => Asset(
            id: row['id'] as String,
            folderId: row['folderId'] as String,
            title: row['title'] as String,
            type: row['type'] as String,
            notes: row['notes'] as String?,
            imagePath: row['imagePath'] as String?,
            tags: row['tags'] as String?,
            filePath: row['filePath'] as String?,
            createdAt: row['createdAt'] as int,
            updatedAt: row['updatedAt'] as int),
        arguments: [folderId]);
  }

  @override
  Future<List<Asset>> searchAssets(String query) async {
    return _queryAdapter.queryList(
        'SELECT * FROM Asset WHERE title LIKE ?1 OR notes LIKE ?1 OR tags LIKE ?1 ORDER BY updatedAt DESC',
        mapper: (Map<String, Object?> row) => Asset(id: row['id'] as String, folderId: row['folderId'] as String, title: row['title'] as String, type: row['type'] as String, notes: row['notes'] as String?, imagePath: row['imagePath'] as String?, tags: row['tags'] as String?, filePath: row['filePath'] as String?, createdAt: row['createdAt'] as int, updatedAt: row['updatedAt'] as int),
        arguments: [query]);
  }

  @override
  Future<List<String>> getAllTags() async {
    return _queryAdapter.queryList(
        'SELECT DISTINCT tags FROM Asset WHERE tags IS NOT NULL AND tags != \"\"',
        mapper: (Map<String, Object?> row) => row.values.first as String);
  }

  @override
  Future<void> insertAsset(Asset asset) async {
    await _assetInsertionAdapter.insert(asset, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateAsset(Asset asset) async {
    await _assetUpdateAdapter.update(asset, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteAsset(Asset asset) async {
    await _assetDeletionAdapter.delete(asset);
  }
}

class _$AssetFolderDao extends AssetFolderDao {
  _$AssetFolderDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _assetFolderInsertionAdapter = InsertionAdapter(
            database,
            'AssetFolder',
            (AssetFolder item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'icon': item.icon,
                  'description': item.description,
                  'parentId': item.parentId,
                  'createdAt': item.createdAt
                }),
        _assetFolderUpdateAdapter = UpdateAdapter(
            database,
            'AssetFolder',
            ['id'],
            (AssetFolder item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'icon': item.icon,
                  'description': item.description,
                  'parentId': item.parentId,
                  'createdAt': item.createdAt
                }),
        _assetFolderDeletionAdapter = DeletionAdapter(
            database,
            'AssetFolder',
            ['id'],
            (AssetFolder item) => <String, Object?>{
                  'id': item.id,
                  'name': item.name,
                  'icon': item.icon,
                  'description': item.description,
                  'parentId': item.parentId,
                  'createdAt': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<AssetFolder> _assetFolderInsertionAdapter;

  final UpdateAdapter<AssetFolder> _assetFolderUpdateAdapter;

  final DeletionAdapter<AssetFolder> _assetFolderDeletionAdapter;

  @override
  Future<List<AssetFolder>> getAllFolders() async {
    return _queryAdapter.queryList(
        'SELECT * FROM AssetFolder ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => AssetFolder(
            id: row['id'] as String,
            name: row['name'] as String,
            icon: row['icon'] as String,
            description: row['description'] as String?,
            parentId: row['parentId'] as String?,
            createdAt: row['createdAt'] as int));
  }

  @override
  Future<List<AssetFolder>> getRootFolders() async {
    return _queryAdapter.queryList(
        'SELECT * FROM AssetFolder WHERE parentId IS NULL ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => AssetFolder(
            id: row['id'] as String,
            name: row['name'] as String,
            icon: row['icon'] as String,
            description: row['description'] as String?,
            parentId: row['parentId'] as String?,
            createdAt: row['createdAt'] as int));
  }

  @override
  Future<List<AssetFolder>> getChildFolders(String parentId) async {
    return _queryAdapter.queryList(
        'SELECT * FROM AssetFolder WHERE parentId = ?1 ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => AssetFolder(
            id: row['id'] as String,
            name: row['name'] as String,
            icon: row['icon'] as String,
            description: row['description'] as String?,
            parentId: row['parentId'] as String?,
            createdAt: row['createdAt'] as int),
        arguments: [parentId]);
  }

  @override
  Future<void> insertFolder(AssetFolder folder) async {
    await _assetFolderInsertionAdapter.insert(folder, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateFolder(AssetFolder folder) async {
    await _assetFolderUpdateAdapter.update(folder, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteFolder(AssetFolder folder) async {
    await _assetFolderDeletionAdapter.delete(folder);
  }
}

class _$DayEntryDao extends DayEntryDao {
  _$DayEntryDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _dayEntryInsertionAdapter = InsertionAdapter(
            database,
            'DayEntry',
            (DayEntry item) => <String, Object?>{
                  'id': item.id,
                  'date': item.date,
                  'mood': item.mood,
                  'diary': item.diary
                }),
        _dayEntryUpdateAdapter = UpdateAdapter(
            database,
            'DayEntry',
            ['id'],
            (DayEntry item) => <String, Object?>{
                  'id': item.id,
                  'date': item.date,
                  'mood': item.mood,
                  'diary': item.diary
                }),
        _dayEntryDeletionAdapter = DeletionAdapter(
            database,
            'DayEntry',
            ['id'],
            (DayEntry item) => <String, Object?>{
                  'id': item.id,
                  'date': item.date,
                  'mood': item.mood,
                  'diary': item.diary
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<DayEntry> _dayEntryInsertionAdapter;

  final UpdateAdapter<DayEntry> _dayEntryUpdateAdapter;

  final DeletionAdapter<DayEntry> _dayEntryDeletionAdapter;

  @override
  Future<DayEntry?> getEntryForDate(String date) async {
    return _queryAdapter.query('SELECT * FROM DayEntry WHERE date = ?1 LIMIT 1',
        mapper: (Map<String, Object?> row) => DayEntry(
            id: row['id'] as String,
            date: row['date'] as String,
            mood: row['mood'] as String?,
            diary: row['diary'] as String?),
        arguments: [date]);
  }

  @override
  Future<List<DayEntry>> getEntriesInRange(
    String from,
    String to,
  ) async {
    return _queryAdapter.queryList(
        'SELECT * FROM DayEntry WHERE date >= ?1 AND date <= ?2',
        mapper: (Map<String, Object?> row) => DayEntry(
            id: row['id'] as String,
            date: row['date'] as String,
            mood: row['mood'] as String?,
            diary: row['diary'] as String?),
        arguments: [from, to]);
  }

  @override
  Future<void> insertEntry(DayEntry entry) async {
    await _dayEntryInsertionAdapter.insert(entry, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateEntry(DayEntry entry) async {
    await _dayEntryUpdateAdapter.update(entry, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteEntry(DayEntry entry) async {
    await _dayEntryDeletionAdapter.delete(entry);
  }
}

class _$WeekTodoDao extends WeekTodoDao {
  _$WeekTodoDao(
    this.database,
    this.changeListener,
  )   : _queryAdapter = QueryAdapter(database),
        _weekTodoInsertionAdapter = InsertionAdapter(
            database,
            'WeekTodo',
            (WeekTodo item) => <String, Object?>{
                  'id': item.id,
                  'weekStart': item.weekStart,
                  'title': item.title,
                  'isDone': item.isDone ? 1 : 0,
                  'createdAt': item.createdAt
                }),
        _weekTodoUpdateAdapter = UpdateAdapter(
            database,
            'WeekTodo',
            ['id'],
            (WeekTodo item) => <String, Object?>{
                  'id': item.id,
                  'weekStart': item.weekStart,
                  'title': item.title,
                  'isDone': item.isDone ? 1 : 0,
                  'createdAt': item.createdAt
                }),
        _weekTodoDeletionAdapter = DeletionAdapter(
            database,
            'WeekTodo',
            ['id'],
            (WeekTodo item) => <String, Object?>{
                  'id': item.id,
                  'weekStart': item.weekStart,
                  'title': item.title,
                  'isDone': item.isDone ? 1 : 0,
                  'createdAt': item.createdAt
                });

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<WeekTodo> _weekTodoInsertionAdapter;

  final UpdateAdapter<WeekTodo> _weekTodoUpdateAdapter;

  final DeletionAdapter<WeekTodo> _weekTodoDeletionAdapter;

  @override
  Future<List<WeekTodo>> getTodosForWeek(String weekStart) async {
    return _queryAdapter.queryList(
        'SELECT * FROM WeekTodo WHERE weekStart = ?1 ORDER BY createdAt ASC',
        mapper: (Map<String, Object?> row) => WeekTodo(
            id: row['id'] as String,
            weekStart: row['weekStart'] as String,
            title: row['title'] as String,
            isDone: (row['isDone'] as int) != 0,
            createdAt: row['createdAt'] as int),
        arguments: [weekStart]);
  }

  @override
  Future<void> insertTodo(WeekTodo todo) async {
    await _weekTodoInsertionAdapter.insert(todo, OnConflictStrategy.abort);
  }

  @override
  Future<void> updateTodo(WeekTodo todo) async {
    await _weekTodoUpdateAdapter.update(todo, OnConflictStrategy.abort);
  }

  @override
  Future<void> deleteTodo(WeekTodo todo) async {
    await _weekTodoDeletionAdapter.delete(todo);
  }
}
