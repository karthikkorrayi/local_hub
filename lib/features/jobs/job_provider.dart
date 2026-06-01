import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/job_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/job.dart';

final jobListProvider = FutureProvider<List<Job>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.jobDao.getAllJobs();
});

final kanbanColumnsProvider = Provider<Map<String, List<Job>>>((ref) {
  const statuses = ['wishlist', 'applied', 'interview', 'offer', 'rejected'];
  final jobsAsync = ref.watch(jobListProvider);
  return jobsAsync.when(
    data: (jobs) => {for (final s in statuses) s: jobs.where((j) => j.status == s).toList()},
    loading: () => {for (final s in statuses) s: []},
    error: (_, __) => {for (final s in statuses) s: []},
  );
});

class JobActions {
  final JobDao _dao;
  final Ref _ref;
  JobActions(this._dao, this._ref);

  Future<void> addJob(Job job) async {
    await _dao.insertJob(job);
    _ref.invalidate(jobListProvider);
  }

  Future<void> updateJob(Job job) async {
    await _dao.updateJob(job);
    _ref.invalidate(jobListProvider);
  }

  Future<void> deleteJob(Job job) async {
    await _dao.deleteJob(job);
    _ref.invalidate(jobListProvider);
  }
}

final jobActionsProvider = FutureProvider<JobActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return JobActions(db.jobDao, ref);
});