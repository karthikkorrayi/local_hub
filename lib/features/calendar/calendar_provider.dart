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

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final calendarViewProvider = StateProvider<String>((ref) => 'month');

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String weekStartKey(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return dateKey(monday);
}

final dayEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.calendarDao.getEventsForDate(dateKey(day));
});

final monthEventsProvider = FutureProvider<Map<String, List<CalendarEvent>>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  final from = DateTime(day.year, day.month, 1);
  final to = DateTime(day.year, day.month + 1, 0);
  final events = await db.calendarDao.getEventsInRange(dateKey(from), dateKey(to));
  final map = <String, List<CalendarEvent>>{};
  for (final e in events) { map.putIfAbsent(e.date, () => []).add(e); }
  return map;
});

final monthMoodProvider = FutureProvider<Map<String, String>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  final from = DateTime(day.year, day.month, 1);
  final to = DateTime(day.year, day.month + 1, 0);
  final entries = await db.dayEntryDao.getEntriesInRange(dateKey(from), dateKey(to));
  return { for (final e in entries) if (e.mood != null) e.date: e.mood! };
});

final dayEntryProvider = FutureProvider<DayEntry?>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.dayEntryDao.getEntryForDate(dateKey(day));
});

final weekEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  final start = day.subtract(Duration(days: day.weekday - 1));
  final end = start.add(const Duration(days: 6));
  return db.calendarDao.getEventsInRange(dateKey(start), dateKey(end));
});

final weekTodosProvider = FutureProvider<List<WeekTodo>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.weekTodoDao.getTodosForWeek(weekStartKey(day));
});

final allJobsForPickerProvider = FutureProvider<List<Job>>((ref) async {
  return ref.watch(jobListProvider.future);
});

class CalendarActions {
  final CalendarDao _calDao;
  final DayEntryDao _entryDao;
  final WeekTodoDao _todoDao;
  final Ref _ref;

  CalendarActions(this._calDao, this._entryDao, this._todoDao, this._ref);

  Future<void> addEvent(CalendarEvent event) async {
    await _calDao.insertEvent(event);
    _ref.invalidate(dayEventsProvider); _ref.invalidate(monthEventsProvider); _ref.invalidate(weekEventsProvider);
  }

  Future<void> updateEvent(CalendarEvent event) async {
    await _calDao.updateEvent(event);
    _ref.invalidate(dayEventsProvider); _ref.invalidate(monthEventsProvider); _ref.invalidate(weekEventsProvider);
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    await _calDao.deleteEvent(event);
    _ref.invalidate(dayEventsProvider); _ref.invalidate(monthEventsProvider); _ref.invalidate(weekEventsProvider);
  }

  Future<void> toggleEventDone(CalendarEvent event) async {
    final updated = CalendarEvent(
      id: event.id, title: event.title, description: event.description,
      date: event.date, startTime: event.startTime, endTime: event.endTime,
      category: event.category, itemType: event.itemType, contactInfo: event.contactInfo,
      attachmentPath: event.attachmentPath, isDone: !event.isDone,
      linkedJobId: event.linkedJobId, linkedJobTitle: event.linkedJobTitle,
      createdAt: event.createdAt,
    );
    await updateEvent(updated);
  }

  Future<void> saveDayEntry(DayEntry entry) async {
    final existing = await _entryDao.getEntryForDate(entry.date);
    if (existing == null) { await _entryDao.insertEntry(entry); } else { await _entryDao.updateEntry(entry); }
    _ref.invalidate(dayEntryProvider); _ref.invalidate(monthMoodProvider);
  }

  Future<void> addTodo(WeekTodo todo) async {
    await _todoDao.insertTodo(todo); _ref.invalidate(weekTodosProvider);
  }

  Future<void> toggleTodo(WeekTodo todo) async {
    final updated = WeekTodo(id: todo.id, weekStart: todo.weekStart,
        title: todo.title, isDone: !todo.isDone, createdAt: todo.createdAt);
    await _todoDao.updateTodo(updated); _ref.invalidate(weekTodosProvider);
  }

  Future<void> deleteTodo(WeekTodo todo) async {
    await _todoDao.deleteTodo(todo); _ref.invalidate(weekTodosProvider);
  }
}

final calendarActionsProvider = FutureProvider<CalendarActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CalendarActions(db.calendarDao, db.dayEntryDao, db.weekTodoDao, ref);
});