import 'dart:io';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/android_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/job.dart';
import 'job_provider.dart';

const _kStatuses = ['applied', 'assessment', 'interview', 'offer', 'rejected', 'withdrawn'];
const _kLabels = {
  'wishlist': 'Wishlist', 'applied': 'Applied', 'assessment': 'Assessment',
  'interview': 'Interview', 'offer': 'Offer', 'rejected': 'Rejected', 'withdrawn': 'Withdrawn',
};
const _kStatusColors = {
  'wishlist': Color(0xFF9CA3AF), 'applied':   Color(0xFF1EC86A), 'assessment': Color(0xFF3B82F6),
  'interview': Color(0xFFF59E0B), 'offer':     Color(0xFF10B981),
  'rejected':  Color(0xFFEF4444), 'withdrawn': Color(0xFF6B7280),
};
const _kStatusIcons = {
  'wishlist': Icons.bookmark_outline_rounded,
  'applied':   Icons.send_rounded,
  'assessment': Icons.assignment_outlined,
  'interview': Icons.people_outline_rounded,
  'offer':     Icons.celebration_outlined,
  'rejected':  Icons.cancel_outlined,
  'withdrawn': Icons.undo_rounded,
};

// ── Screen ─────────────────────────────────────────────────────────────────────
class JobsScreen extends ConsumerStatefulWidget {
  const JobsScreen({super.key});

  @override
  ConsumerState<JobsScreen> createState() => _JobsScreenState();
}

class _JobsScreenState extends ConsumerState<JobsScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStatus(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final columns = ref.watch(kanbanColumnsProvider);

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: Text('Job Tracker',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
        actions: [
          if (!Platform.isAndroid)
            IconButton(
              icon: const Icon(Icons.add_rounded),
              onPressed: () => _showJobForm(context),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () => _showJobForm(context),
          backgroundColor: AndroidTheme.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          _StatusPipelineBar(
            currentIndex: _currentIndex,
            columns: columns,
            onTap: _goToStatus,
          ),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemCount: _kStatuses.length,
              itemBuilder: (_, i) {
                final status = _kStatuses[i];
                return _JobList(
                  status: status,
                  jobs: columns[status] ?? [],
                  onEdit: (job) => _showJobForm(context, existing: job),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showJobForm(BuildContext context, {Job? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JobFormSheet(existing: existing),
    );
  }
}

// ── Status pipeline bar ────────────────────────────────────────────────────────
class _StatusPipelineBar extends StatelessWidget {
  final int currentIndex;
  final Map<String, List<Job>> columns;
  final void Function(int) onTap;

  const _StatusPipelineBar({
    required this.currentIndex,
    required this.columns,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AndroidTheme.card,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          Row(
            children: List.generate(_kStatuses.length * 2 - 1, (i) {
              if (i.isOdd) {
                final leftIndex = i ~/ 2;
                final active = leftIndex < currentIndex;
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 2,
                    color: active ? AndroidTheme.primary : AndroidTheme.divider,
                  ),
                );
              }
              final index = i ~/ 2;
              final status = _kStatuses[index];
              final color = _kStatusColors[status]!;
              final isActive = index == currentIndex;
              final isPast = index < currentIndex;

              return GestureDetector(
                onTap: () => onTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isActive || isPast ? color : AndroidTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isActive || isPast ? color : AndroidTheme.divider,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    _kStatusIcons[status],
                    size: 14,
                    color: isActive || isPast ? Colors.white : AndroidTheme.textTertiary,
                  ),
                ),
              ).animate(target: isActive ? 1 : 0).scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.15, 1.15),
                    duration: 200.ms,
                    curve: Curves.easeOut,
                  );
            }),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_kStatuses.length, (i) {
              final status = _kStatuses[i];
              final color = _kStatusColors[status]!;
              final isActive = i == currentIndex;
              final count = columns[status]?.length ?? 0;

              return GestureDetector(
                onTap: () => onTap(i),
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? color : AndroidTheme.textTertiary,
                  ),
                  child: Text(
                    '${_kLabels[status]}\n$count',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ── Job list ───────────────────────────────────────────────────────────────────
class _JobList extends StatelessWidget {
  final String status;
  final List<Job> jobs;
  final void Function(Job) onEdit;

  const _JobList({
    required this.status,
    required this.jobs,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _kStatusIcons[status],
              size: 48,
              color: AndroidTheme.textTertiary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No ${_kLabels[status]} jobs',
              style: GoogleFonts.inter(
                  color: AndroidTheme.textTertiary, fontSize: 15),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: jobs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _JobCard(job: jobs[i], onEdit: onEdit)
          .animate()
          .fadeIn(delay: (i * 50).ms, duration: 300.ms)
          .slideY(begin: 0.1, end: 0, duration: 300.ms),
    );
  }
}

// ── Job card ───────────────────────────────────────────────────────────────────
class _JobCard extends ConsumerWidget {
  final Job job;
  final void Function(Job) onEdit;

  const _JobCard({required this.job, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      onTap: () => context.push('/jobs/${job.id}', extra: job),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15, color: AndroidTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(job.company,
                      style: GoogleFonts.inter(color: AndroidTheme.textSecondary, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Last modified', style: GoogleFonts.inter(fontSize: 10, color: AndroidTheme.textTertiary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_formatDate(job.updatedAt), style: GoogleFonts.inter(fontSize: 12, color: AndroidTheme.textSecondary, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

// ── Detail row helper ──────────────────────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AndroidTheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: AndroidTheme.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AndroidTheme.textTertiary,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
                      fontSize: 14,
                      color: valueColor ?? AndroidTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit form ────────────────────────────────────────────────────────────
class _JobFormSheet extends ConsumerStatefulWidget {
  final Job? existing;
  const _JobFormSheet({this.existing});

  @override
  ConsumerState<_JobFormSheet> createState() => _JobFormSheetState();
}

class _JobFormSheetState extends ConsumerState<_JobFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _company;
  late final TextEditingController _notes;
  late final TextEditingController _url;
  late String _status;
  String? _resumePath;
  DateTime? _appliedAt;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final j = widget.existing;
    _title      = TextEditingController(text: j?.title ?? '');
    _company    = TextEditingController(text: j?.company ?? '');
    _notes      = TextEditingController(text: j?.notes ?? '');
    _url        = TextEditingController(text: j?.url ?? '');
    _status     = j?.status ?? 'applied';
    _resumePath = j?.resumePath;
    _appliedAt  = j?.appliedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(j!.appliedAt!)
        : null;
  }

  @override
  void dispose() {
    _title.dispose();
    _company.dispose();
    _notes.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    const typeGroup = XTypeGroup(
        label: 'Documents', extensions: ['pdf', 'doc', 'docx']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) setState(() => _resumePath = file.path);
  }

  Future<void> _pickAppliedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AndroidTheme.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _appliedAt = picked);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _company.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final existing = widget.existing;
      final job = Job(
        id:         existing?.id ?? const Uuid().v4(),
        title:      _title.text.trim(),
        company:    _company.text.trim(),
        status:     _status,
        notes:      _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        url:        _url.text.trim().isEmpty ? null : _url.text.trim(),
        resumePath: _resumePath,
        appliedAt:  _appliedAt?.millisecondsSinceEpoch,
        createdAt:  existing?.createdAt ?? now,
        updatedAt:  now,
      );
      final actions = await ref.read(jobActionsProvider.future);
      if (existing == null) {
        await actions.addJob(job);
      } else {
        await actions.updateJob(job);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving job: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final resumeName = _resumePath?.split('/').last;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  isEdit ? 'Edit Job' : 'Add Job',
                  style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (isEdit)
                  Text(
                    'Updated ${_formatTs(widget.existing!.updatedAt)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: AndroidTheme.textTertiary),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Job title *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _company,
              decoration: const InputDecoration(labelText: 'Company *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),

            Text(
              'Status',
              style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AndroidTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _kStatuses.map((s) {
                  final selected = _status == s;
                  final color = _kStatusColors[s]!;
                  return GestureDetector(
                    onTap: () => setState(() => _status = s),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? color : AndroidTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? color : AndroidTheme.divider),
                      ),
                      child: Text(
                        _kLabels[s]!,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? Colors.white
                                : AndroidTheme.textSecondary),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _pickAppliedDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AndroidTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AndroidTheme.divider),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: AndroidTheme.textSecondary),
                    const SizedBox(width: 10),
                    Text(
                      _appliedAt != null
                          ? 'Applied: ${_appliedAt!.day.toString().padLeft(2, '0')}/${_appliedAt!.month.toString().padLeft(2, '0')}/${_appliedAt!.year}'
                          : 'Set applied date',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _appliedAt != null
                              ? AndroidTheme.textPrimary
                              : AndroidTheme.textTertiary),
                    ),
                    const Spacer(),
                    if (_appliedAt != null)
                      GestureDetector(
                        onTap: () => setState(() => _appliedAt = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AndroidTheme.textTertiary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _notes,
              decoration: const InputDecoration(
                  labelText: 'Notes', alignLabelWithHint: true),
              maxLines: 3,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _url,
              decoration: const InputDecoration(
                labelText: 'Job URL',
                prefixIcon: Icon(Icons.link_rounded, size: 18),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickResume,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: resumeName != null
                      ? AndroidTheme.primaryLight
                      : AndroidTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: resumeName != null
                        ? AndroidTheme.primary
                        : AndroidTheme.divider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      size: 18,
                      color: resumeName != null
                          ? AndroidTheme.primary
                          : AndroidTheme.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        resumeName ?? 'Attach resume (PDF/DOC)',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: resumeName != null
                                ? AndroidTheme.primary
                                : AndroidTheme.textTertiary,
                            fontWeight: resumeName != null
                                ? FontWeight.w500
                                : FontWeight.w400),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (resumeName != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() => _resumePath = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: AndroidTheme.primary),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Saving…'
                  : isEdit
                      ? 'Save Changes'
                      : 'Add Job'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTs(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }
}

// ── Dedicated job details page ────────────────────────────────────────────────
class JobDetailsScreen extends ConsumerStatefulWidget {
  final String jobId;
  final Job? initialJob;
  const JobDetailsScreen({super.key, required this.jobId, this.initialJob});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {

  void _showEditForm(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JobFormSheet(existing: job),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncJob = ref.watch(jobByIdProvider(widget.jobId));
    final job = asyncJob.valueOrNull ?? widget.initialJob;

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(title: const Text('Job Details')),
      body: job == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 23, fontWeight: FontWeight.w800, color: AndroidTheme.textPrimary)),
                            const SizedBox(height: 6),
                            Text(job.company, style: GoogleFonts.inter(fontSize: 16, color: AndroidTheme.textSecondary, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Applied', style: GoogleFonts.inter(fontSize: 10, color: AndroidTheme.textTertiary, fontWeight: FontWeight.w700)),
                            Text(_formatDate(job.appliedAt), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            Text('Modified', style: GoogleFonts.inter(fontSize: 10, color: AndroidTheme.textTertiary, fontWeight: FontWeight.w700)),
                            Text(_formatDate(job.updatedAt), textAlign: TextAlign.right, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(status: job.status),
                      const SizedBox(height: 16),
                      _ActionRow(icon: Icons.notes_rounded, label: 'Detail Notes', value: job.notes?.isNotEmpty == true ? job.notes! : 'No detail notes yet'),
                      if (job.url != null && job.url!.isNotEmpty)
                        _ActionRow(icon: Icons.open_in_new_rounded, label: 'Job URL', value: job.url!, onTap: () => _launchExternal(job.url!)),
                      if (job.resumePath != null && job.resumePath!.isNotEmpty)
                        _ActionRow(icon: Icons.description_outlined, label: 'Uploaded Resume', value: job.resumePath!.split('/').last, onTap: () => _showResumePreview(context, job.resumePath!)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: FilledButton.icon(icon: const Icon(Icons.add_comment_outlined, size: 18), label: const Text('Comment'), onPressed: () => _showNoteDialog(context, job))),
                    const SizedBox(width: 10),
                    Expanded(child: OutlinedButton.icon(icon: const Icon(Icons.swap_horiz_rounded, size: 18), label: const Text('Update Status'), onPressed: () => _showStatusDialog(context, job))),
                  ],
                ),
                const SizedBox(height: 12),
                _TimelineCard(title: 'Comment History', entries: job.noteTimeline),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text('Edit'),
                      onPressed: () => _showEditForm(context, job),
                    ),
                    const SizedBox(width: 16),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline_rounded, size: 16),
                      label: const Text('Delete'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      onPressed: () => _confirmDelete(context, job),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  static String _formatDate(int? ms) {
    if (ms == null) return 'Not set';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Future<void> _launchExternal(String value) async {
    final uri = Uri.tryParse(value.startsWith('http') ? value : 'https://$value');
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showResumePreview(BuildContext context, String path) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => _ResumeViewerPage(path: path)));
  }

  void _showNoteDialog(BuildContext context, Job job) {
    final note = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(controller: note, decoration: const InputDecoration(labelText: 'Daily comment'), maxLines: 4, autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: () async {
            if (note.text.trim().isEmpty) return;
            final actions = await ref.read(jobActionsProvider.future);
            await actions.appendNote(job, JobTimelineEntry(date: DateTime.now().millisecondsSinceEpoch, text: note.text.trim()));
            if (dialogContext.mounted) Navigator.of(dialogContext).pop();
          }, child: const Text('Save')),
        ],
      ),
    );
  }

  void _showStatusDialog(BuildContext context, Job job) {
    var selected = job.status;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Status'),
          content: DropdownButtonFormField<String>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Status'),
            items: _kStatuses.map((s) => DropdownMenuItem(value: s, child: Text(_kLabels[s]!))).toList(),
            onChanged: (v) => setState(() => selected = v ?? selected),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () async {
              final actions = await ref.read(jobActionsProvider.future);
              await actions.changeStatus(job, selected, DateTime.now().millisecondsSinceEpoch);
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('Remove "${job.title}" at ${job.company}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          TextButton(onPressed: () async {
            Navigator.of(dialogContext).pop();
            final actions = await ref.read(jobActionsProvider.future);
            await actions.deleteJob(job);
            if (context.mounted) context.pop();
          }, child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

class _ResumeViewerPage extends StatelessWidget {
  final String path;
  const _ResumeViewerPage({required this.path});
  @override
  Widget build(BuildContext context) {
    final isPdf = path.toLowerCase().endsWith('.pdf');
    return Scaffold(
      appBar: AppBar(title: Text(path.split('/').last)),
      body: isPdf
          ? SfPdfViewer.file(File(path))
          : Center(child: Image.file(File(path), fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Text('Preview unavailable for this file type.'))),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = _kStatusColors[status] ?? AndroidTheme.textTertiary;
    return Chip(
      avatar: Icon(_kStatusIcons[status] ?? Icons.circle, size: 16, color: color),
      label: Text(_kLabels[status] ?? status),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle: GoogleFonts.inter(color: color, fontWeight: FontWeight.w700),
      side: BorderSide.none,
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ActionRow({required this.icon, required this.label, required this.value, this.onTap});
  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AndroidTheme.primary),
        title: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AndroidTheme.textTertiary)),
        subtitle: Text(value, style: GoogleFonts.inter(fontSize: 14, color: onTap == null ? AndroidTheme.textPrimary : AndroidTheme.primary)),
        onTap: onTap,
      );
}

class _TimelineCard extends StatelessWidget {
  final String title;
  final List<JobTimelineEntry> entries;
  const _TimelineCard({required this.title, required this.entries});
  @override
  Widget build(BuildContext context) => AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text('No history yet', style: GoogleFonts.inter(color: AndroidTheme.textTertiary))
            else
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_JobDetailsScreenState._formatDate(e.date), style: GoogleFonts.inter(fontSize: 12, color: AndroidTheme.textTertiary, fontWeight: FontWeight.w700)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(e.text, style: GoogleFonts.inter(fontSize: 14, color: AndroidTheme.textPrimary))),
                    ]),
                  )),
          ],
        ),
      );
}