import 'package:floor/floor.dart';
import '../models/wishlist_item.dart';

@dao
abstract class WishlistDao {
  @Query('SELECT * FROM WishlistItem ORDER BY createdAt DESC')
  Future<List<WishlistItem>> getAllItems();

  @Query('SELECT * FROM WishlistItem WHERE isPurchased = :purchased')
  Future<List<WishlistItem>> getItemsByPurchased(bool purchased);

  @insert
  Future<void> insertItem(WishlistItem item);

  @update
  Future<void> updateItem(WishlistItem item);

  @delete
  Future<void> deleteItem(WishlistItem item);
}