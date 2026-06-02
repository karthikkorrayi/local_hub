import 'dart:convert';

import 'package:floor/floor.dart';

@entity
class Job {
  @PrimaryKey(autoGenerate: false)
  final String id;
  final String title;
  final String company;
  final String status;
  final String? notes;
  final String? url;
  final String? resumePath;
  final int? appliedAt;
  final String? noteHistory;
  final String? statusHistory;
  final int createdAt;
  final int updatedAt;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.status,
    this.notes,
    this.url,
    this.resumePath,
    this.appliedAt,
    this.noteHistory,
    this.statusHistory,
    required this.createdAt,
    required this.updatedAt,
  });

  List<JobTimelineEntry> get noteTimeline =>
      _decodeTimeline(noteHistory, fallbackNote: notes, fallbackDate: appliedAt ?? createdAt);

  List<JobTimelineEntry> get statusTimeline =>
      _decodeTimeline(statusHistory, fallbackNote: status, fallbackDate: updatedAt);

  Job copyWith({
    String? title,
    String? company,
    String? status,
    String? notes,
    String? url,
    String? resumePath,
    int? appliedAt,
    String? noteHistory,
    String? statusHistory,
    int? updatedAt,
  }) =>
      Job(
        id: id,
        title: title ?? this.title,
        company: company ?? this.company,
        status: status ?? this.status,
        notes: notes ?? this.notes,
        url: url ?? this.url,
        resumePath: resumePath ?? this.resumePath,
        appliedAt: appliedAt ?? this.appliedAt,
        noteHistory: noteHistory ?? this.noteHistory,
        statusHistory: statusHistory ?? this.statusHistory,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class JobTimelineEntry {
  final int date;
  final String text;

  const JobTimelineEntry({required this.date, required this.text});

  Map<String, dynamic> toJson() => {'date': date, 'text': text};
}

List<JobTimelineEntry> _decodeTimeline(String? raw, {String? fallbackNote, int? fallbackDate}) {
  final entries = <JobTimelineEntry>[];
  if (raw != null && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final date = item['date'];
            final text = item['text'];
            if (date is int && text is String && text.trim().isNotEmpty) {
              entries.add(JobTimelineEntry(date: date, text: text.trim()));
            }
          }
        }
      }
    } on FormatException {
      // Keep older malformed history from breaking the details page.
    }
  }
  if (entries.isEmpty && fallbackNote != null && fallbackNote.trim().isNotEmpty) {
    entries.add(JobTimelineEntry(
      date: fallbackDate ?? DateTime.now().millisecondsSinceEpoch,
      text: fallbackNote.trim(),
    ));
  }
  entries.sort((a, b) => a.date.compareTo(b.date));
  return entries;
}

String encodeJobTimeline(List<JobTimelineEntry> entries) =>
    jsonEncode(entries.map((e) => e.toJson()).toList());