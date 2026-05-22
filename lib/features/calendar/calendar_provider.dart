import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/calendar_dao.dart';
import '../../data/daos/day_entry_dao.dart';
import '../../data/daos/week_todo_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/day_entry.dart';
import '../../data/models/week_todo.dart';
import '../../data/models/job.dart';
import '../jobs/job_provider.dart';

// ── Selected day & view mode ───────────────────────────────────────────────────
final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarViewProvider = StateProvider<bool>((ref) => true); // true = month

// ── Date helpers ───────────────────────────────────────────────────────────────
String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String weekStartKey(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return dateKey(monday);
}

// ── Events for selected day ────────────────────────────────────────────────────
final dayEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.calendarDao.getEventsForDate(dateKey(day));
});

// ── Events in a month range (for dot indicators) ──────────────────────────────
final monthEventsProvider = FutureProvider<Map<String, List<CalendarEvent>>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  final from = DateTime(day.year, day.month, 1);
  final to = DateTime(day.year, day.month + 1, 0);
  final events = await db.calendarDao.getEventsInRange(
    dateKey(from), dateKey(to),
  );
  final map = <String, List<CalendarEvent>>{};
  for (final e in events) {
    map.putIfAbsent(e.date, () => []).add(e);
  }
  return map;
});

// ── Day entry (mood + diary) ───────────────────────────────────────────────────
final dayEntryProvider = FutureProvider<DayEntry?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.dayEntryDao.getEntryForDate(dateKey(day));
});

// ── Week todos ─────────────────────────────────────────────────────────────────
final weekTodosProvider = FutureProvider<List<WeekTodo>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.weekTodoDao.getTodosForWeek(weekStartKey(day));
});

// ── All jobs (for job linkage picker) ─────────────────────────────────────────
final allJobsForPickerProvider = FutureProvider<List<Job>>((ref) async {
  return ref.watch(jobListProvider.future);
});

// ── Actions ───────────────────────────────────────────────────────────────────
class CalendarActions {
  final CalendarDao _calDao;
  final DayEntryDao _entryDao;
  final WeekTodoDao _todoDao;
  final Ref _ref;

  CalendarActions(this._calDao, this._entryDao, this._todoDao, this._ref);

  // Events
  Future<void> addEvent(CalendarEvent event) async {
    await _calDao.insertEvent(event);
    _ref.invalidate(dayEventsProvider);
    _ref.invalidate(monthEventsProvider);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _calDao.updateEvent(event);
    _ref.invalidate(dayEventsProvider);
    _ref.invalidate(monthEventsProvider);
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    await _calDao.deleteEvent(event);
    _ref.invalidate(dayEventsProvider);
    _ref.invalidate(monthEventsProvider);
  }

  // Day entry (mood + diary)
  Future<void> saveDayEntry(DayEntry entry) async {
    final existing = await _entryDao.getEntryForDate(entry.date);
    if (existing == null) {
      await _entryDao.insertEntry(entry);
    } else {
      await _entryDao.updateEntry(entry);
    }
    _ref.invalidate(dayEntryProvider);
  }

  // Week todos
  Future<void> addTodo(WeekTodo todo) async {
    await _todoDao.insertTodo(todo);
    _ref.invalidate(weekTodosProvider);
  }

  Future<void> toggleTodo(WeekTodo todo) async {
    final updated = WeekTodo(
      id: todo.id,
      weekStart: todo.weekStart,
      title: todo.title,
      isDone: !todo.isDone,
      createdAt: todo.createdAt,
    );
    await _todoDao.updateTodo(updated);
    _ref.invalidate(weekTodosProvider);
  }

  Future<void> deleteTodo(WeekTodo todo) async {
    await _todoDao.deleteTodo(todo);
    _ref.invalidate(weekTodosProvider);
  }
}

final calendarActionsProvider = FutureProvider<CalendarActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CalendarActions(db.calendarDao, db.dayEntryDao, db.weekTodoDao, ref);
});