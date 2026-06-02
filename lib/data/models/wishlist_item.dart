import 'package:floor/floor.dart';

@entity
class WishlistItem {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String name;
  final double? price;
  final String? imageUrl;
  final String? category;
  final String? productUrl;
  final int? targetPurchaseAt;
  final bool isPurchased;
  final int? purchasedAt;
  final int createdAt;

  const WishlistItem({
    required this.id,
    required this.name,
    this.price,
    this.imageUrl,
    this.category,
    this.productUrl,
    this.targetPurchaseAt,
    required this.isPurchased,
    this.purchasedAt,
    required this.createdAt,
  });

  WishlistItem copyWith({
    String? name,
    double? price,
    String? imageUrl,
    String? category,
    String? productUrl,
    int? targetPurchaseAt,
    bool? isPurchased,
    int? purchasedAt,
  }) =>
      WishlistItem(
        id: id,
        name: name ?? this.name,
        price: price ?? this.price,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        productUrl: productUrl ?? this.productUrl,
        targetPurchaseAt: targetPurchaseAt ?? this.targetPurchaseAt,
        isPurchased: isPurchased ?? this.isPurchased,
        purchasedAt: purchasedAt ?? this.purchasedAt,
        createdAt: createdAt,
      );
}