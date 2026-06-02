import 'package:floor/floor.dart';
import '../models/asset_folder.dart';

@dao
abstract class AssetFolderDao {
  @Query('SELECT * FROM AssetFolder ORDER BY createdAt ASC')
  Future<List<AssetFolder>> getAllFolders();

  @Query('SELECT * FROM AssetFolder WHERE parentId IS NULL ORDER BY createdAt ASC')
  Future<List<AssetFolder>> getRootFolders();

  @Query('SELECT * FROM AssetFolder WHERE parentId = :parentId ORDER BY createdAt ASC')
  Future<List<AssetFolder>> getChildFolders(String parentId);

  @insert
  Future<void> insertFolder(AssetFolder folder);

  @update
  Future<void> updateFolder(AssetFolder folder);

  @delete
  Future<void> deleteFolder(AssetFolder folder);
}