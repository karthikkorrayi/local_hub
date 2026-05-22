import 'package:floor/floor.dart';
import '../models/calendar_event.dart';

@dao
abstract class CalendarDao {
  @Query('SELECT * FROM CalendarEvent WHERE date = :date ORDER BY startTime ASC')
  Future<List<CalendarEvent>> getEventsForDate(String date);

  @Query('SELECT * FROM CalendarEvent WHERE date >= :from AND date <= :to ORDER BY date ASC, startTime ASC')
  Future<List<CalendarEvent>> getEventsInRange(String from, String to);

  @Query('SELECT * FROM CalendarEvent WHERE linkedJobId = :jobId ORDER BY date ASC')
  Future<List<CalendarEvent>> getEventsForJob(String jobId);

  @insert
  Future<void> insertEvent(CalendarEvent event);

  @update
  Future<void> updateEvent(CalendarEvent event);

  @delete
  Future<void> deleteEvent(CalendarEvent event);
}