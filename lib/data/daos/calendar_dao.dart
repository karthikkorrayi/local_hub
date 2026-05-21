import 'package:floor/floor.dart';
import '../models/calendar_event.dart';

@dao
abstract class CalendarDao {
  @Query('SELECT * FROM CalendarEvent ORDER BY startAt ASC')
  Future<List<CalendarEvent>> getAllEvents();

  @Query('SELECT * FROM CalendarEvent WHERE startAt >= :from AND startAt <= :to ORDER BY startAt ASC')
  Future<List<CalendarEvent>> getEventsInRange(int from, int to);

  @insert
  Future<void> insertEvent(CalendarEvent event);

  @update
  Future<void> updateEvent(CalendarEvent event);

  @delete
  Future<void> deleteEvent(CalendarEvent event);
}