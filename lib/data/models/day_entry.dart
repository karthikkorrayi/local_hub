import 'package:floor/floor.dart';

@entity
class DayEntry {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String date;
  final String? mood;
  final String? diary;

  const DayEntry({
    required this.id, required this.date, this.mood, this.diary,
  });
}