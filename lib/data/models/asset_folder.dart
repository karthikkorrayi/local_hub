import 'package:floor/floor.dart';

@entity
class AssetFolder {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String name;
  final String icon;
  final String? description;
  final int createdAt;

  const AssetFolder({
    required this.id, required this.name,
    required this.icon, this.description, required this.createdAt,
  });
}