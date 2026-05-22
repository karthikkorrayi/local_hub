import 'package:floor/floor.dart';

@entity
class WeekTodo {
  @PrimaryKey(autoGenerate: false)
  final String id;

  /// ISO date of the Monday that starts this week e.g. '2026-05-18'
  final String weekStart;

  final String title;
  final bool isDone;
  final int createdAt;

  const WeekTodo({
    required this.id,
    required this.weekStart,
    required this.title,
    required this.isDone,
    required this.createdAt,
  });
}