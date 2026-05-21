import 'package:floor/floor.dart';
import '../models/asset.dart';

@dao
abstract class AssetDao {
  @Query('SELECT * FROM Asset ORDER BY createdAt DESC')
  Future<List<Asset>> getAllAssets();

  @Query('SELECT * FROM Asset WHERE type = :type ORDER BY createdAt DESC')
  Future<List<Asset>> getAssetsByType(String type);

  @insert
  Future<void> insertAsset(Asset asset);

  @update
  Future<void> updateAsset(Asset asset);

  @delete
  Future<void> deleteAsset(Asset asset);
}