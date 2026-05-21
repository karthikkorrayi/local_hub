import 'package:floor/floor.dart';

@entity
class CalendarEvent {
  @PrimaryKey(autoGenerate: false)
  final String id;

  final String title;
  final String? description;
  final int startAt;   // Unix timestamp ms
  final int endAt;     // Unix timestamp ms
  final bool isAllDay;

  /// e.g. 'work', 'personal', 'reminder'
  final String? category;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startAt,
    required this.endAt,
    required this.isAllDay,
    this.category,
  });
}