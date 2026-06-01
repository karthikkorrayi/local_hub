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
  final int createdAt;
  final int updatedAt;

  const Job({
    required this.id, required this.title, required this.company,
    required this.status, this.notes, this.url, this.resumePath,
    this.appliedAt, required this.createdAt, required this.updatedAt,
  });
}