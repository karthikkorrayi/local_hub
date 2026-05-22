import 'package:floor/floor.dart';

@entity
class CalendarEvent {
  @PrimaryKey(autoGenerate: false)
  final String id;

  final String title;
  final String? description;

  /// Stored as 'yyyy-MM-dd' for the day it belongs to
  final String date;

  /// Optional time as 'HH:mm' e.g. '14:30'. Null = all-day
  final String? startTime;
  final String? endTime;

  /// 'payment' | 'ticket' | 'planning' | 'free' | 'other'
  final String category;

  /// Optional linked Job id
  final String? linkedJobId;

  /// Optional linked Job title (denormalized for display — avoids a join)
  final String? linkedJobTitle;

  final int createdAt;

  const CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.date,
    this.startTime,
    this.endTime,
    required this.category,
    this.linkedJobId,
    this.linkedJobTitle,
    required this.createdAt,
  });
}