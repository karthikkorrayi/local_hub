import 'package:floor/floor.dart';

@entity
class CalendarEvent {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String title;
  final String? description;
  final String date;
  final String? startTime;
  final String? endTime;
  final String category;
  final String? itemType;
  final String? contactInfo;
  final String? attachmentPath;
  final bool isDone;
  final String? linkedJobId;
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
    this.itemType,
    this.contactInfo,
    this.attachmentPath,
    this.isDone = false,
    this.linkedJobId,
    this.linkedJobTitle,
    required this.createdAt,
  });
}