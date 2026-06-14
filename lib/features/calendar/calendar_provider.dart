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

// ── Recurring birthday expansion ──────────────────────────────────────────────
// Takes ONLY recurring birthday source records and generates virtual copies
// for years other than the stored year. The original stored record is already
// included in raw (fetched by getEventsInRange), so we must not add it again.
//
// IMPORTANT: raw (non-recurring) and recurring are kept SEPARATE before this
// call to avoid duplicating the original birthday in the same month/year.
List<CalendarEvent> _virtualBirthdaysForYear(
    List<CalendarEvent> recurringSource, int year, int month) {
  final result = <CalendarEvent>[];
  for (final b in recurringSource) {
    if (b.birthDay == null || b.birthMonth == null) continue;
    if (b.birthMonth != month) continue;
    // Determine the year stored in the record
    final storedYear = int.tryParse(b.date.substring(0, 4)) ?? year;
    if (storedYear == year) continue; // already in raw for this month/year
    final virtualDate =
        '$year-${b.birthMonth.toString().padLeft(2, '0')}-${b.birthDay!.toString().padLeft(2, '0')}';
    result.add(CalendarEvent(
      id:          '${b.id}_$year',
      title:       b.title,
      description: b.description,
      date:        virtualDate,
      category:    b.category,
      itemType:    b.itemType,
      isDone:      false,
      createdAt:   b.createdAt,
      birthDay:    b.birthDay,
      birthMonth:  b.birthMonth,
      isRecurring: true,
    ));
  }
  return result;
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Events for the selected day, including recurring birthdays on that day.
final dayEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(selectedDayProvider);

  // Stored events for this exact date (includes real birthday record if stored on this date)
  final stored = await db.calendarDao.getEventsForDate(dateKey(day));
  final storedIds = stored.map((e) => e.id).toSet();

  // Add virtual recurring birthday copies for OTHER years only
  final allRecurring = await db.calendarDao.getRecurringBirthdays();
  final extra = <CalendarEvent>[];
  for (final b in allRecurring) {
    if (b.birthDay != day.day || b.birthMonth != day.month) continue;
    final storedYear = int.tryParse(b.date.substring(0, 4)) ?? day.year;
    if (storedYear == day.year) continue; // already in stored
    final virtualId = '${b.id}_${day.year}';
    if (storedIds.contains(virtualId)) continue;
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
  return [...stored, ...extra];
});

/// Map of date→events for the focused month (used by TableCalendar markers).
final monthEventsProvider =
    FutureProvider<Map<String, List<CalendarEvent>>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(focusedMonthProvider);
  final from = DateTime(day.year, day.month, 1);
  final to   = DateTime(day.year, day.month + 1, 0);

  // Stored events for the range — includes real birthday records stored in this month
  final raw = await db.calendarDao.getEventsInRange(dateKey(from), dateKey(to));

  // Only generate virtual copies for recurring birthdays NOT already in raw
  final allRecurring = await db.calendarDao.getRecurringBirthdays();
  final rawIds = raw.map((e) => e.id).toSet();
  final virtuals = _virtualBirthdaysForYear(
      allRecurring.where((b) => !rawIds.contains(b.id)).toList(),
      day.year, day.month);

  final all = [...raw, ...virtuals];
  final map = <String, List<CalendarEvent>>{};
  for (final e in all) {
    map.putIfAbsent(e.date, () => []).add(e);
  }
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

/// Events for the current week, including recurring birthdays.
final weekEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db    = await ref.watch(databaseProvider.future);
  final day   = ref.watch(selectedDayProvider);
  final start = day.subtract(Duration(days: day.weekday - 1));
  final end   = start.add(const Duration(days: 6));
  final raw   = await db.calendarDao.getEventsInRange(dateKey(start), dateKey(end));
  final rawIds = raw.map((e) => e.id).toSet();

  final allRecurring = await db.calendarDao.getRecurringBirthdays();
  final extra = <CalendarEvent>[];
  for (int i = 0; i < 7; i++) {
    final d = start.add(Duration(days: i));
    for (final b in allRecurring) {
      if (b.birthDay != d.day || b.birthMonth != d.month) continue;
      if (rawIds.contains(b.id)) continue; // real record already in raw
      final virtualId = '${b.id}_${d.year}';
      if (rawIds.contains(virtualId)) continue;
      extra.add(CalendarEvent(
        id:          virtualId,
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
  final all = [...raw, ...extra];
  all.sort((a, b) => a.date.compareTo(b.date));
  return all;
});

/// All events for the focused month as a flat list (used by _ActivitySection).
final monthEventListProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final db  = await ref.watch(databaseProvider.future);
  final day = ref.watch(focusedMonthProvider);
  final raw = await db.calendarDao.getEventsInRange(
      dateKey(DateTime(day.year, day.month, 1)),
      dateKey(DateTime(day.year, day.month + 1, 0)));
  final rawIds = raw.map((e) => e.id).toSet();
  final allRecurring = await db.calendarDao.getRecurringBirthdays();
  final virtuals = _virtualBirthdaysForYear(
      allRecurring.where((b) => !rawIds.contains(b.id)).toList(),
      day.year, day.month);
  final all = [...raw, ...virtuals];
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
  final CalendarDao _calDao;
  final DayEntryDao _entryDao;
  final WeekTodoDao _todoDao;
  final Ref         _ref;

  CalendarActions(this._calDao, this._entryDao, this._todoDao, this._ref);

  Future<void> addEvent(CalendarEvent event) async {
    await _calDao.insertEvent(event);
    _refresh();
  }

  Future<void> updateEvent(CalendarEvent event) async {
    // Virtual recurring IDs have the form `realId_YEAR` — strip the suffix
    if (event.isRecurring && _isVirtualId(event.id)) {
      final realId  = _realId(event.id);
      final updated = CalendarEvent(
        id:             realId,
        title:          event.title,
        description:    event.description,
        date:           event.date,
        startTime:      event.startTime,
        endTime:        event.endTime,
        category:       event.category,
        itemType:       event.itemType,
        contactInfo:    event.contactInfo,
        attachmentPath: event.attachmentPath,
        isDone:         event.isDone,
        linkedJobId:    event.linkedJobId,
        linkedJobTitle: event.linkedJobTitle,
        createdAt:      event.createdAt,
        birthDay:       event.birthDay,
        birthMonth:     event.birthMonth,
        isRecurring:    event.isRecurring,
      );
      await _calDao.updateEvent(updated);
    } else {
      await _calDao.updateEvent(event);
    }
    _refresh();
  }

  Future<void> deleteEvent(CalendarEvent event) async {
    if (event.isRecurring && _isVirtualId(event.id)) {
      await _calDao.deleteEventById(_realId(event.id));
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

  // Virtual IDs look like `uuid_2027` — a real UUID followed by `_YEAR` (4 digits)
  static bool _isVirtualId(String id) {
    final last = id.lastIndexOf('_');
    if (last < 0) return false;
    final suffix = id.substring(last + 1);
    return suffix.length == 4 && int.tryParse(suffix) != null;
  }

  static String _realId(String id) => id.substring(0, id.lastIndexOf('_'));
}

final calendarActionsProvider = FutureProvider<CalendarActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return CalendarActions(db.calendarDao, db.dayEntryDao, db.weekTodoDao, ref);
});