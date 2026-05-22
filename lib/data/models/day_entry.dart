import 'package:floor/floor.dart';

@entity
class DayEntry {
  @PrimaryKey(autoGenerate: false)
  final String id;

  /// Stored as 'yyyy-MM-dd' string for easy querying
  final String date;

  /// Single emoji e.g. '😊'
  final String? mood;

  /// Free-text diary note
  final String? diary;

  const DayEntry({
    required this.id,
    required this.date,
    this.mood,
    this.diary,
  });
}