import 'package:floor/floor.dart';
import '../models/asset.dart';

@dao
abstract class AssetDao {
  @Query('SELECT * FROM Asset WHERE folderId = :folderId ORDER BY updatedAt DESC')
  Future<List<Asset>> getAssetsByFolder(String folderId);

  @Query('''
    SELECT * FROM Asset 
    WHERE title LIKE :query 
    OR notes LIKE :query 
    OR tags LIKE :query
    ORDER BY updatedAt DESC
  ''')
  Future<List<Asset>> searchAssets(String query);

  @Query('SELECT DISTINCT tags FROM Asset WHERE tags IS NOT NULL AND tags != ""')
  Future<List<String>> getAllTags();

  @insert
  Future<void> insertAsset(Asset asset);

  @update
  Future<void> updateAsset(Asset asset);

  @delete
  Future<void> deleteAsset(Asset asset);
}