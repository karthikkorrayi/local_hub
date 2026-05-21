import 'package:floor/floor.dart';

@entity
class Job {
  @PrimaryKey(autoGenerate: false)
  final String id;

  final String title;
  final String company;

  /// Values: 'wishlist', 'applied', 'interview', 'offer', 'rejected'
  final String status;

  final String? notes;
  final String? url;
  final int createdAt; // Unix timestamp in milliseconds
  final int updatedAt;

  const Job({
    required this.id,
    required this.title,
    required this.company,
    required this.status,
    this.notes,
    this.url,
    required this.createdAt,
    required this.updatedAt,
  });
}