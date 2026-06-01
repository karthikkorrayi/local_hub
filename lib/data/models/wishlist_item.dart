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
  final bool isPurchased;
  final int createdAt;

  const WishlistItem({
    required this.id, required this.name, this.price, this.imageUrl,
    this.category, this.productUrl, required this.isPurchased, required this.createdAt,
  });
}