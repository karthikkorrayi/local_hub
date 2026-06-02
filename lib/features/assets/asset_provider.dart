import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/asset_dao.dart';
import '../../data/daos/asset_folder_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/asset.dart';
import '../../data/models/asset_folder.dart';

final selectedFolderProvider  = StateProvider<AssetFolder?>((_) => null);
final assetSearchQueryProvider = StateProvider<String>((_) => '');
final selectedTagProvider     = StateProvider<String?>((_) => null);

final folderListProvider = FutureProvider<List<AssetFolder>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.assetFolderDao.getAllFolders();
});

final childFolderListProvider = FutureProvider<List<AssetFolder>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final folder = ref.watch(selectedFolderProvider);
  if (folder == null) return db.assetFolderDao.getRootFolders();
  return db.assetFolderDao.getChildFolders(folder.id);
});

final assetListProvider = FutureProvider<List<Asset>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final query = ref.watch(assetSearchQueryProvider);
  final folder = ref.watch(selectedFolderProvider);
  if (query.trim().isNotEmpty) return db.assetDao.searchAssets('%${query.trim()}%');
  return db.assetDao.getAssetsByFolder(folder?.id ?? 'root');
});

final filteredAssetListProvider = Provider<List<Asset>>((ref) {
  final tag = ref.watch(selectedTagProvider);
  final assetsAsync = ref.watch(assetListProvider);
  return assetsAsync.when(data: (assets) => tag == null ? assets : assets.where((a) => a.tagList.contains(tag)).toList(), loading: () => [], error: (_, __) => []);
});

final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final rawTags = await db.assetDao.getAllTags();
  final tagSet = <String>{};
  for (final raw in rawTags) { if (raw.isNotEmpty) tagSet.addAll(raw.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty)); }
  return tagSet.toList()..sort();
});

class AssetActions {
  final AssetDao _assetDao; final AssetFolderDao _folderDao; final Ref _ref;
  AssetActions(this._assetDao, this._folderDao, this._ref);
  Future<void> addFolder(AssetFolder folder) async { await _folderDao.insertFolder(folder); _refreshFolders(); }
  Future<void> updateFolder(AssetFolder folder) async { await _folderDao.updateFolder(folder); _refreshFolders(); }
  Future<void> deleteFolder(AssetFolder folder) async { await _folderDao.deleteFolder(folder); _refreshFolders(); }
  Future<void> addAsset(Asset asset) async { await _assetDao.insertAsset(asset); _refreshAssets(); }
  Future<void> updateAsset(Asset asset) async { await _assetDao.updateAsset(asset); _refreshAssets(); }
  Future<void> deleteAsset(Asset asset) async { await _assetDao.deleteAsset(asset); _refreshAssets(); }
  void _refreshFolders(){ _ref.invalidate(folderListProvider); _ref.invalidate(childFolderListProvider); }
  void _refreshAssets(){ _ref.invalidate(assetListProvider); _ref.invalidate(allTagsProvider); }
}

final assetActionsProvider = FutureProvider<AssetActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return AssetActions(db.assetDao, db.assetFolderDao, ref);
});