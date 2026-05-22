import 'package:floor/floor.dart';

@entity
class Asset {
  @PrimaryKey(autoGenerate: false)
  final String id;

  final String folderId;
  final String title;

  /// 'document' | 'image' | 'credential' | 'license' | 'other'
  final String type;

  /// Rich text / detailed notes
  final String? notes;

  /// Local file path for attached image
  final String? imagePath;

  /// Comma-separated tags e.g. 'work,important,2026'
  final String? tags;

  final int createdAt;
  final int updatedAt;

  const Asset({
    required this.id,
    required this.folderId,
    required this.title,
    required this.type,
    this.notes,
    this.imagePath,
    this.tags,
    required this.createdAt,
    required this.updatedAt,
  });

  List<String> get tagList =>
      tags == null || tags!.isEmpty ? [] : tags!.split(',');
}