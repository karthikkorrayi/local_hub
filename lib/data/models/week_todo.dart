import 'package:floor/floor.dart';

@entity
class WeekTodo {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String weekStart;
  final String title;
  final bool isDone;
  final int createdAt;

  const WeekTodo({
    required this.id, required this.weekStart, required this.title,
    required this.isDone, required this.createdAt,
  });
}