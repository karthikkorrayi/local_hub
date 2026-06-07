import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/calendar_dao.dart';
import '../../data/daos/day_entry_dao.dart';
import '../../data/daos/week_todo_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/day_entry.dart';
import '../../data/models/week_todo.dart';
import '../jobs/job_provider.dart';
import '../../data/models/job.dart';

final selectedDayProvider =
    StateProvider<DateTime>((ref) => DateTime.now());
final focusedMonthProvider = StateProvider<DateTime>(
    (ref) => DateTime(DateTime.now().year, DateTime.now().month));
final calendarViewProvider = StateProvider<String>((ref) => 'day');

String dateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String weekStartKey(DateTime d) {
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return dateKey(monday);
}

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

// ── Recurring birthday expansion ─────────────────────────────────────────────
/// Takes all raw DB events and injects virtual recurring-birthday entries for
/// the displayed month so they appear every year without extra DB records.
List<CalendarEvent> _expandRecurring(
    List<CalendarEvent> raw, int year, int month) {
  final result = <CalendarEvent>[];
  final seen   = <String>{};  // prevents duplicate real entries

  for (final e in raw) {
    if (!e.isRecurring) {
      result.add(e);
      seen.add(e.id);
      continue;
    }
    // The stored date is the original year. For each recurring event we also
    // generate a virtual copy dated to the current view-year if different.
    result.add(e);
    seen.add(e.id);
    if (e.birthDay != null && e.birthMonth != null && e.birthMonth == month) {
      // Check if the view-year differs from stored year
      final storedYear = int.tryParse(e.date.substring(0, 4)) ?? year;
      if (storedYear != year) {
        // Synthesise a display-only copy with this year's date
        final virtualDate =
            '$year-${e.birthMonth.toString().padLeft(2, '0')}-${e.birthDay!.toString().padLeft(2, '0')}';
        final virtualId = '${e.id}_$year';
        if (!seen.contains(virtualId)) {
          result.add(CalendarEvent(
            id:          virtualId,
            title:       e.title,
            description: e.description,
            date:        virtualDate,
            category:    e.category,
            itemType:    e.itemType,
            isDone:      false,
            createdAt:   e.createdAt,
            birthDay:    e.birthDay,
            birthMonth:  e.birthMonth,
            isRecurring: true,
          ));
          seen.add(virtualId);
        }
      }
    }
  }
  return result;
}

// ── Providers ─────────────────────────────────────────────────────────────────

final dayEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  // Fetch stored events for this date
  final stored = await db.calendarDao.getEventsForDate(dateKey(day));
  // Also fetch all recurring birthdays to check if any land on this day
  final allRecurring =
      await db.calendarDao.getRecurringBirthdays();
  final extra = <CalendarEvent>[];
  for (final b in allRecurring) {
    if (b.birthDay == day.day && b.birthMonth == day.month) {
      final virtualId = '${b.id}_${day.year}';
      // Only add if not already in stored (i.e. original year matches)
      if (!stored.any((s) => s.id == b.id || s.id == virtualId)) {
        extra.add(CalendarEvent(
          id:          virtualId,
          title:       b.title,
          description: b.description,
          date:        dateKey(day),
          category:    b.category,
          itemType:    b.itemType,
          isDone:      false,
          createdAt:   b.createdAt,
          birthDay:    b.birthDay,
          birthMonth:  b.birthMonth,
          isRecurring: true,
        ));
      }
    }
  }
  return [...stored, ...extra];
});

final monthEventsProvider =
    FutureProvider<Map<String, List<CalendarEvent>>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(focusedMonthProvider);
  final from = DateTime(day.year, day.month, 1);
  final to   = DateTime(day.year, day.month + 1, 0);
  final raw  = await db.calendarDao.getEventsInRange(
      dateKey(from), dateKey(to));
  // Add recurring birthdays for this month
  final recurring = await db.calendarDao.getRecurringBirthdays();
  final expanded  = _expandRecurring([...raw, ...recurring], day.year, day.month);
  final map = <String, List<CalendarEvent>>{};
  for (final e in expanded) { map.putIfAbsent(e.date, () => []).add(e); }
  return map;
});

final monthMoodProvider =
    FutureProvider<Map<String, DayEntry>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(focusedMonthProvider);
  final from = DateTime(day.year, day.month, 1);
  final to   = DateTime(day.year, day.month + 1, 0);
  final entries = await db.dayEntryDao
      .getEntriesInRange(dateKey(from), dateKey(to));
  return {for (final e in entries) e.date: e};
});

final dayEntryProvider = FutureProvider<DayEntry?>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.dayEntryDao.getEntryForDate(dateKey(day));
});

final weekEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db    = await ref.watch(databaseProvider.future);
  final day   = ref.watch(selectedDayProvider);
  final start = day.subtract(Duration(days: day.weekday - 1));
  final end   = start.add(const Duration(days: 6));
  final raw   = await db.calendarDao.getEventsInRange(
      dateKey(start), dateKey(end));
  final recurring = await db.calendarDao.getRecurringBirthdays();
  // Expand recurring for each day in the week
  final all = <CalendarEvent>[...raw];
  for (int i = 0; i < 7; i++) {
    final d = start.add(Duration(days: i));
    for (final b in recurring) {
      if (b.birthDay == d.day && b.birthMonth == d.month &&
          !all.any((e) => e.id == b.id)) {
        all.add(CalendarEvent(
          id:          '${b.id}_${d.year}',
          title:       b.title,
          description: b.description,
          date:        dateKey(d),
          category:    b.category,
          itemType:    b.itemType,
          isDone:      false,
          createdAt:   b.createdAt,
          birthDay:    b.birthDay,
          birthMonth:  b.birthMonth,
          isRecurring: true,
        ));
      }
    }
  }
  all.sort((a, b) => a.date.compareTo(b.date));
  return all;
});

final monthEventListProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(focusedMonthProvider);
  final raw = await db.calendarDao.getEventsInRange(
      dateKey(DateTime(day.year, day.month, 1)),
      dateKey(DateTime(day.year, day.month + 1, 0)));
  final recurring = await db.calendarDao.getRecurringBirthdays();
  final all = _expandRecurring([...raw, ...recurring], day.year, day.month);
  all.sort((a, b) => a.date.compareTo(b.date));
  return all;
});

final weekTodosProvider = FutureProvider<List<WeekTodo>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);
  return db.weekTodoDao.getTodosForWeek(weekStartKey(day));
});

final allJobsForPickerProvider = FutureProvider<List<Job>>((ref) async {
  return ref.watch(jobListProvider.future);
});

// ── Calendar actions ──────────────────────────────────────────────────────────
class CalendarActions {
  final CalendarDao  _calDao;
  final DayEntryDao  _entryDao;
  final WeekTodoDao  _todoDao;
  final Ref          _ref;

  CalendarActions(this._calDao, this._entryDao, this._todoDao, this._ref);

  Future<void> addEvent(CalendarEvent event) async {
    await _calDao.insertEvent(event);
    _refresh();
  }

  Future<void> updateEvent(CalendarEvent event) async {
    // For virtual recurring entries (id ends with _YEAR) we update the
    // original record by stripping the year suffix.
    if (event.isRecurring && event.id.contains('_')) {
      final realId = event.id.substring(0, event.id.lastIndexOf('_'));
      final updated = CalendarEvent(
        id:          realId,
        title:       event.title,
        description: event.description,
        date:        event.date,
        startTime:   event.startTime,
        endTime:     event.endTime,
        category:    event.category,
        itemType:    event.itemType,
        contactInfo: event.contactInfo,
        attachmentPath: event.attachmentPath,
        isDone:      event.isDone,
        linkedJobId: event.linkedJobId,
        linkedJobTitle: event.linkedJobTitle,
        createdAt:   event.createdAt,
        birthDay:    event.birthDay,
        birthMonth:  event.birthMonth,
        isRecurring: event.isRecurring,
      );
      await _calDao.updateEvent(updated);
    } else {
      await _calDao.updateEvent(event);
    }
    _refresh();
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    if (event.isRecurring && event.id.contains('_')) {
      // Delete the real recurring record
      final realId = event.id.substring(0, event.id.lastIndexOf('_'));
      await _calDao.deleteEventById(realId);
    } else {
      await _calDao.deleteEvent(event);
    }
    _refresh();
  }

  Future<void> toggleEventDone(CalendarEvent event) async {
    await updateEvent(event.copyWith(isDone: !event.isDone));
  }

  Future<void> saveDayEntry(DayEntry entry) async {
    final existing = await _entryDao.getEntryForDate(entry.date);
    if (existing == null) {
      await _entryDao.insertEntry(entry);
    } else {
      await _entryDao.updateEntry(entry);
    }
    _ref.invalidate(dayEntryProvider);
    _ref.invalidate(monthMoodProvider);
  }

  Future<void> addTodo(WeekTodo todo) async {
    await _todoDao.insertTodo(todo);
    _ref.invalidate(weekTodosProvider);
  }

  Future<void> toggleTodo(WeekTodo todo) async {
    await _todoDao.updateTodo(WeekTodo(
        id: todo.id, weekStart: todo.weekStart,
        title: todo.title, isDone: !todo.isDone, createdAt: todo.createdAt));
    _ref.invalidate(weekTodosProvider);
  }

  Future<void> deleteTodo(WeekTodo todo) async {
    await _todoDao.deleteTodo(todo);
    _ref.invalidate(weekTodosProvider);
  }

  void _refresh() {
    _ref.invalidate(dayEventsProvider);
    _ref.invalidate(monthEventsProvider);
    _ref.invalidate(weekEventsProvider);
    _ref.invalidate(monthEventListProvider);
  }
}

final calendarActionsProvider = FutureProvider<CalendarActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CalendarActions(db.calendarDao, db.dayEntryDao, db.weekTodoDao, ref);
});