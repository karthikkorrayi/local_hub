import 'package:floor/floor.dart';

@entity
class AssetFolder {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String name;
  final String icon;
  final int createdAt;

  const AssetFolder({
    required this.id, required this.name,
    required this.icon, required this.createdAt,
  });
}