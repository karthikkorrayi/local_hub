import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/daos/job_dao.dart';
import '../../data/database/database_provider.dart';
import '../../data/models/job.dart';

final jobListProvider = FutureProvider<List<Job>>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return db.jobDao.getAllJobs();
});


final jobByIdProvider = FutureProvider.family<Job?, String>((ref, id) async {
  final db = await ref.watch(databaseProvider.future);
  return db.jobDao.getJobById(id);
});

final kanbanColumnsProvider = Provider<Map<String, List<Job>>>((ref) {
  const statuses = ['applied', 'assessment', 'interview', 'offer', 'rejected', 'withdrawn'];
  final jobsAsync = ref.watch(jobListProvider);
  return jobsAsync.when(
    data: (jobs) => {
      for (final s in statuses)
        s: jobs.where((j) => j.status == s || (s == 'applied' && j.status == 'wishlist')).toList()
    },
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
    _ref.invalidate(jobByIdProvider(job.id));
  }

  Future<void> updateJob(Job job) async {
    await _dao.updateJob(job);
    _ref.invalidate(jobListProvider);
    _ref.invalidate(jobByIdProvider(job.id));
  }

  Future<void> appendNote(Job job, JobTimelineEntry entry) async {
    final timeline = [...job.noteTimeline, entry];
    final updated = job.copyWith(
      notes: entry.text,
      noteHistory: encodeJobTimeline(timeline),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await updateJob(updated);
  }

  Future<void> changeStatus(Job job, String status, int date) async {
    final timeline = [...job.statusTimeline, JobTimelineEntry(date: date, text: status)];
    final updated = job.copyWith(
      status: status,
      statusHistory: encodeJobTimeline(timeline),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await updateJob(updated);
  }

  Future<void> deleteJob(Job job) async {
    await _dao.deleteJob(job);
    _ref.invalidate(jobListProvider);
    _ref.invalidate(jobByIdProvider(job.id));
  }
}

final jobActionsProvider = FutureProvider<JobActions>((ref) async {
  final db = await ref.watch(databaseProvider.future);
  return JobActions(db.jobDao, ref);
});