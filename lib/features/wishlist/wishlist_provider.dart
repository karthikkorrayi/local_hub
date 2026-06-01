import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/wishlist_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/wishlist_item.dart';

enum WishlistFilter { all, unpurchased, purchased }

final wishlistFilterProvider = StateProvider<WishlistFilter>((_) => WishlistFilter.all);

final wishlistListProvider = FutureProvider<List<WishlistItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.wishlistDao.getAllItems();
});

final filteredWishlistProvider = Provider<List<WishlistItem>>((ref) {
  final filter = ref.watch(wishlistFilterProvider);
  final itemsAsync = ref.watch(wishlistListProvider);
  return itemsAsync.when(
    data: (items) {
      switch (filter) {
        case WishlistFilter.purchased: return items.where((i) => i.isPurchased).toList();
        case WishlistFilter.unpurchased: return items.where((i) => !i.isPurchased).toList();
        case WishlistFilter.all: return items;
      }
    },
    loading: () => [], error: (_, __) => [],
  );
});

class WishlistActions {
  final WishlistDao _dao;
  final Ref _ref;
  WishlistActions(this._dao, this._ref);

  Future<void> addItem(WishlistItem item) async { await _dao.insertItem(item); _ref.invalidate(wishlistListProvider); }
  Future<void> updateItem(WishlistItem item) async { await _dao.updateItem(item); _ref.invalidate(wishlistListProvider); }
  Future<void> deleteItem(WishlistItem item) async { await _dao.deleteItem(item); _ref.invalidate(wishlistListProvider); }
  Future<void> togglePurchased(WishlistItem item) async {
    final updated = WishlistItem(id: item.id, name: item.name, price: item.price,
        imageUrl: item.imageUrl, category: item.category, productUrl: item.productUrl,
        isPurchased: !item.isPurchased, createdAt: item.createdAt);
    await _dao.updateItem(updated);
    _ref.invalidate(wishlistListProvider);
  }
}

final wishlistActionsProvider = FutureProvider<WishlistActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return WishlistActions(db.wishlistDao, ref);
});