import 'package:floor/floor.dart';

@entity
class Asset {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String folderId;
  final String title;
  final String type;
  final String? notes;
  final String? imagePath;
  final String? tags;
  final int createdAt;
  final int updatedAt;

  const Asset({
    required this.id, required this.folderId, required this.title,
    required this.type, this.notes, this.imagePath, this.tags,
    required this.createdAt, required this.updatedAt,
  });

  List<String> get tagList =>
      tags == null || tags!.isEmpty ? [] : tags!.split(',');
}