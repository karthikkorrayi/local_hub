import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/asset_dao.dart';
import '../../data/daos/asset_folder_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_folder.dart';

// ── Selected folder ────────────────────────────────────────────────────────────
final selectedFolderProvider = StateProvider<AssetFolder?>((ref) => null);

// ── Search query ───────────────────────────────────────────────────────────────
final assetSearchQueryProvider = StateProvider<String>((ref) => '');

// ── Selected tag filter ────────────────────────────────────────────────────────
final selectedTagProvider = StateProvider<String?>((ref) => null);

// ── Folders ────────────────────────────────────────────────────────────────────
final folderListProvider = FutureProvider<List<AssetFolder>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.assetFolderDao.getAllFolders();
});

// ── Assets — search OR folder view ────────────────────────────────────────────
final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final query = ref.watch(assetSearchQueryProvider);
  final folder = ref.watch(selectedFolderProvider);

  if (query.trim().isNotEmpty) {
    return db.assetDao.searchAssets('%${query.trim()}%');
  }
  if (folder != null) {
    return db.assetDao.getAssetsByFolder(folder.id);
  }
  return [];
});

// ── Filtered by tag on top of current list ─────────────────────────────────────
final filteredAssetListProvider = Provider<List<Asset>>((ref) {
  final tag = ref.watch(selectedTagProvider);
  final assetsAsync = ref.watch(assetListProvider);

  return assetsAsync.when(
    data: (assets) {
      if (tag == null) return assets;
      return assets.where((a) => a.tagList.contains(tag)).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// ── All unique tags across all assets ─────────────────────────────────────────
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final rawTags = await db.assetDao.getAllTags();
  final tagSet = <String>{};
  for (final raw in rawTags) {
    if (raw.isNotEmpty) {
      tagSet.addAll(raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty));
    }
  }
  return tagSet.toList()..sort();
});

// ── Actions ────────────────────────────────────────────────────────────────────
class AssetActions {
  final AssetDao _assetDao;
  final AssetFolderDao _folderDao;
  final Ref _ref;

  AssetActions(this._assetDao, this._folderDao, this._ref);

  Future<void> addFolder(AssetFolder folder) async {
    await _folderDao.insertFolder(folder);
    _ref.invalidate(folderListProvider);
  }

  Future<void> updateFolder(AssetFolder folder) async {
    await _folderDao.updateFolder(folder);
    _ref.invalidate(folderListProvider);
  }

  Future<void> deleteFolder(AssetFolder folder) async {
    await _folderDao.deleteFolder(folder);
    _ref.invalidate(folderListProvider);
    _ref.invalidate(assetListProvider);
  }

  Future<void> addAsset(Asset asset) async {
    await _assetDao.insertAsset(asset);
    _ref.invalidate(assetListProvider);
    _ref.invalidate(allTagsProvider);
  }

  Future<void> updateAsset(Asset asset) async {
    await _assetDao.updateAsset(asset);
    _ref.invalidate(assetListProvider);
    _ref.invalidate(allTagsProvider);
  }

  Future<void> deleteAsset(Asset asset) async {
    await _assetDao.deleteAsset(asset);
    _ref.invalidate(assetListProvider);
    _ref.invalidate(allTagsProvider);
  }
}

final assetActionsProvider = FutureProvider<AssetActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return AssetActions(db.assetDao, db.assetFolderDao, ref);
});