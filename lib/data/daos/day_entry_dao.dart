import 'package:floor/floor.dart';
import '../models/day_entry.dart';

@dao
abstract class DayEntryDao {
  @Query('SELECT * FROM DayEntry WHERE date = :date LIMIT 1')
  Future<DayEntry?> getEntryForDate(String date);

  @Query('SELECT * FROM DayEntry WHERE date >= :from AND date <= :to')
  Future<List<DayEntry>> getEntriesInRange(String from, String to);

  @insert
  Future<void> insertEntry(DayEntry entry);

  @update
  Future<void> updateEntry(DayEntry entry);

  @delete
  Future<void> deleteEntry(DayEntry entry);
}