import 'package:floor/floor.dart';

@entity
class Asset {
  @PrimaryKey(autoGenerate: false)
  final String id;

  final String name;

  /// e.g. 'document', 'image', 'license', 'credential', 'other'
  final String type;

  final String filePath; // local absolute path on device
  final String? tags;    // comma-separated, e.g. "work,important"
  final String? notes;
  final int createdAt;

  const Asset({
    required this.id,
    required this.name,
    required this.type,
    required this.filePath,
    this.tags,
    this.notes,
    required this.createdAt,
  });
}