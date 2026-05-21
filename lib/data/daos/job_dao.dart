import 'package:floor/floor.dart';
import '../models/job.dart';

@dao
abstract class JobDao {
  @Query('SELECT * FROM Job ORDER BY updatedAt DESC')
  Future<List<Job>> getAllJobs();

  @Query('SELECT * FROM Job WHERE status = :status ORDER BY updatedAt DESC')
  Future<List<Job>> getJobsByStatus(String status);

  @Query('SELECT * FROM Job WHERE id = :id')
  Future<Job?> getJobById(String id);

  @insert
  Future<void> insertJob(Job job);

  @update
  Future<void> updateJob(Job job);

  @delete
  Future<void> deleteJob(Job job);
}