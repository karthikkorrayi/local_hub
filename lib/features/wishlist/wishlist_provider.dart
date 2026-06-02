import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/wishlist_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/wishlist_item.dart';

enum WishlistFilter { ordered, target, gifts }

final wishlistFilterProvider = StateProvider<WishlistFilter>((_) => WishlistFilter.target);

final wishlistListProvider = FutureProvider<List<WishlistItem>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.wishlistDao.getAllItems();
});

final wishlistItemByIdProvider = FutureProvider.family<WishlistItem?, String>((ref, id) async {
  final db = await ref.watch(databaseProvider.future);
  return db.wishlistDao.getItemById(id);
});

final filteredWishlistProvider = Provider<List<WishlistItem>>((ref) {
  final filter = ref.watch(wishlistFilterProvider);
  final itemsAsync = ref.watch(wishlistListProvider);
  return itemsAsync.when(
    data: (items) {
      switch (filter) {
        case WishlistFilter.ordered:
          return items.where((i) => i.isPurchased).toList();
        case WishlistFilter.gifts:
          return items.where((i) => (i.category ?? '').toLowerCase().contains('gift')).toList();
        case WishlistFilter.target:
          return items.where((i) => !i.isPurchased).toList()
            ..sort((a, b) => (a.targetPurchaseAt ?? 1 << 62).compareTo(b.targetPurchaseAt ?? 1 << 62));
      }
    },
    loading: () => [], error: (_, __) => [],
  );
});

class WishlistActions {
  final WishlistDao _dao;
  final Ref _ref;
  WishlistActions(this._dao, this._ref);

  Future<void> addItem(WishlistItem item) async { await _dao.insertItem(item); _refresh(item.id); }
  Future<void> updateItem(WishlistItem item) async { await _dao.updateItem(item); _refresh(item.id); }
  Future<void> deleteItem(WishlistItem item) async { await _dao.deleteItem(item); _refresh(item.id); }
  Future<void> togglePurchased(WishlistItem item) async {
    final updated = item.copyWith(
      isPurchased: !item.isPurchased,
      purchasedAt: item.isPurchased ? null : DateTime.now().millisecondsSinceEpoch,
    );
    await _dao.updateItem(updated);
    _refresh(item.id);
  }

  void _refresh(String id) {
    _ref.invalidate(wishlistListProvider);
    _ref.invalidate(wishlistItemByIdProvider(id));
  }
}

final wishlistActionsProvider = FutureProvider<WishlistActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return WishlistActions(db.wishlistDao, ref);
});