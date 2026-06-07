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

  /// For birthdays only: day-of-month (1–31). Stored so we can
  /// generate the birthday for any year without duplicating records.
  final int? birthDay;

  /// For birthdays only: month-of-year (1–12).
  final int? birthMonth;

  /// True when this event should recur every year (birthdays).
  final bool isRecurring;

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
    this.birthDay,
    this.birthMonth,
    this.isRecurring = false,
  });

  CalendarEvent copyWith({
    String? title,
    String? description,
    String? date,
    String? startTime,
    String? endTime,
    String? category,
    String? itemType,
    String? contactInfo,
    String? attachmentPath,
    bool? isDone,
    String? linkedJobId,
    String? linkedJobTitle,
    int? birthDay,
    int? birthMonth,
    bool? isRecurring,
  }) =>
      CalendarEvent(
        id:             id,
        title:          title          ?? this.title,
        description:    description    ?? this.description,
        date:           date           ?? this.date,
        startTime:      startTime      ?? this.startTime,
        endTime:        endTime        ?? this.endTime,
        category:       category       ?? this.category,
        itemType:       itemType       ?? this.itemType,
        contactInfo:    contactInfo    ?? this.contactInfo,
        attachmentPath: attachmentPath ?? this.attachmentPath,
        isDone:         isDone         ?? this.isDone,
        linkedJobId:    linkedJobId    ?? this.linkedJobId,
        linkedJobTitle: linkedJobTitle ?? this.linkedJobTitle,
        createdAt:      createdAt,
        birthDay:       birthDay       ?? this.birthDay,
        birthMonth:     birthMonth     ?? this.birthMonth,
        isRecurring:    isRecurring    ?? this.isRecurring,
      );
}