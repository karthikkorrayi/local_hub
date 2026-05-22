import 'package:floor/floor.dart';
import '../models/week_todo.dart';

@dao
abstract class WeekTodoDao {
  @Query('SELECT * FROM WeekTodo WHERE weekStart = :weekStart ORDER BY createdAt ASC')
  Future<List<WeekTodo>> getTodosForWeek(String weekStart);

  @insert
  Future<void> insertTodo(WeekTodo todo);

  @update
  Future<void> updateTodo(WeekTodo todo);

  @delete
  Future<void> deleteTodo(WeekTodo todo);
}