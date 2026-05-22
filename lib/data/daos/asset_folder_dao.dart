import 'package:floor/floor.dart';
import '../models/asset_folder.dart';

@dao
abstract class AssetFolderDao {
  @Query('SELECT * FROM AssetFolder ORDER BY createdAt ASC')
  Future<List<AssetFolder>> getAllFolders();

  @insert
  Future<void> insertFolder(AssetFolder folder);

  @update
  Future<void> updateFolder(AssetFolder folder);

  @delete
  Future<void> deleteFolder(AssetFolder folder);
}