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

// Module color shortcuts
const _mc  = AndroidTheme.jobsPrimary;
const _mcl = AndroidTheme.jobsPrimaryLight;

const _kStatuses = ['applied', 'assessment', 'interview', 'offer', 'rejected', 'withdrawn'];
const _kLabels = {
  'wishlist': 'Wishlist', 'applied': 'Applied', 'assessment': 'Assessment',
  'interview': 'Interview', 'offer': 'Offer', 'rejected': 'Rejected', 'withdrawn': 'Withdrawn',
};
const _kStatusColors = {
  'wishlist':   Color(0xFF9CA3AF),
  'applied':    Color(0xFF1EC86A),
  'assessment': Color(0xFF3B82F6),
  'interview':  Color(0xFFF59E0B),
  'offer':      Color(0xFF10B981),
  'rejected':   Color(0xFFEF4444),
  'withdrawn':  Color(0xFF6B7280),
};
const _kStatusIcons = {
  'wishlist':   Icons.bookmark_outline_rounded,
  'applied':    Icons.send_rounded,
  'assessment': Icons.assignment_outlined,
  'interview':  Icons.people_outline_rounded,
  'offer':      Icons.celebration_outlined,
  'rejected':   Icons.cancel_outlined,
  'withdrawn':  Icons.undo_rounded,
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
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    final columns = ref.watch(kanbanColumnsProvider);
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
          backgroundColor: _mc,
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
      color: Theme.of(context).cardTheme.color!,
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
                    color: active ? AndroidTheme.primary : Theme.of(context).dividerColor,
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
                    color: isActive || isPast ? color : Theme.of(context).colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: isActive || isPast ? color : Theme.of(context).dividerColor,
                        width: 2),
                  ),
                  child: Icon(_kStatusIcons[status],
                      size: 14,
                      color: isActive || isPast
                          ? Colors.white
                          : Theme.of(context).hintColor),
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
                    color: isActive ? color : Theme.of(context).hintColor,
                  ),
                  child: Text('${_kLabels[status]}\n$count',
                      textAlign: TextAlign.center),
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

  const _JobList(
      {required this.status, required this.jobs, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    if (jobs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_kStatusIcons[status],
                size: 48,
                color: Theme.of(context).hintColor.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('No ${_kLabels[status]} jobs',
                style: GoogleFonts.inter(
                    color: Theme.of(context).hintColor, fontSize: 15)),
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
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.onSurface),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Text(job.company,
                      style: GoogleFonts.inter(
                          color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Last modified',
                    style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Theme.of(context).hintColor,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(_fmt(job.updatedAt),
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int? ms) {
    if (ms == null) return '—';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
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
  String? _resumeName;
  DateTime? _appliedAt;
  bool _saving = false;
  String? _titleError;
  String? _companyError;

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
    _resumeName = j?.resumePath?.split('/').last;
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

  // Store only the original file path — no copying
  Future<void> _pickResume() async {
    const typeGroup =
        XTypeGroup(label: 'Documents', extensions: ['pdf', 'doc', 'docx']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file != null) {
      setState(() {
        _resumePath = file.path; // original device path, no copy
        _resumeName = file.name;
      });
    }
  }

  Future<void> _pickAppliedDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _appliedAt ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
            colorScheme:
                const ColorScheme.light(primary: _mc)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _appliedAt = picked);
  }

  Future<void> _save() async {
    // Clear previous errors
    setState(() {
      _titleError   = null;
      _companyError = null;
    });

    // Inline validation
    bool valid = true;
    if (_title.text.trim().isEmpty) {
      setState(() => _titleError = 'Job title is required');
      valid = false;
    }
    if (_company.text.trim().isEmpty) {
      setState(() => _companyError = 'Company name is required');
      valid = false;
    }
    if (!valid) return;

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(existing == null
                ? 'Job added successfully'
                : 'Job updated successfully'),
            backgroundColor: _mc,
            duration: const Duration(seconds: 2)));
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      debugPrint('Job save error: $e\n$st');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Unable to save job. Please try again.'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
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
                Text(isEdit ? 'Edit Job' : 'Add Job',
                    style: GoogleFonts.inter(
                        fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                if (isEdit)
                  Text(
                    'Updated ${_fmtDate(widget.existing!.updatedAt)}',
                    style: GoogleFonts.inter(
                        fontSize: 11, color: Theme.of(context).hintColor),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _title,
              decoration: InputDecoration(
                  labelText: 'Job title *',
                  errorText: _titleError),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _titleError = null),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _company,
              decoration: InputDecoration(
                  labelText: 'Company *',
                  errorText: _companyError),
              textCapitalization: TextCapitalization.words,
              onChanged: (_) => setState(() => _companyError = null),
            ),
            const SizedBox(height: 16),
            Text('Status',
                style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                        color: selected ? color : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? color : Theme.of(context).dividerColor),
                      ),
                      child: Text(_kLabels[s]!,
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: selected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickAppliedDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Text(
                      _appliedAt != null
                          ? 'Applied: ${_fmtDate(_appliedAt!.millisecondsSinceEpoch)}'
                          : 'Set applied date',
                      style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _appliedAt != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).hintColor),
                    ),
                    const Spacer(),
                    if (_appliedAt != null)
                      GestureDetector(
                        onTap: () => setState(() => _appliedAt = null),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: Theme.of(context).hintColor),
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
                  prefixIcon: Icon(Icons.link_rounded, size: 18)),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickResume,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _resumeName != null
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: _resumeName != null
                          ? AndroidTheme.primary
                          : Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description_outlined,
                        size: 18,
                        color: _resumeName != null
                            ? AndroidTheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _resumeName ?? 'Attach resume (PDF/DOC)',
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            color: _resumeName != null
                                ? AndroidTheme.primary
                                : Theme.of(context).hintColor,
                            fontWeight: _resumeName != null
                                ? FontWeight.w500
                                : FontWeight.w400),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_resumeName != null)
                      GestureDetector(
                        onTap: () =>
                            setState(() {
                              _resumePath = null;
                              _resumeName = null;
                            }),
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

  static String _fmtDate(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

// ── Job Details Screen ────────────────────────────────────────────────────────
class JobDetailsScreen extends ConsumerStatefulWidget {
  final String jobId;
  final Job? initialJob;
  const JobDetailsScreen(
      {super.key, required this.jobId, this.initialJob});

  @override
  ConsumerState<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends ConsumerState<JobDetailsScreen> {

  static String _fmt(int? ms) {
    if (ms == null) return 'Not set';
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(title: const Text('Job Details')),
      body: job == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // ── Clean header card ──────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: title + company
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Theme.of(context).colorScheme.onSurface)),
                            const SizedBox(height: 4),
                            Text(job.company,
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right: dates — always single line, right-aligned
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          _DateChip(label: 'Applied', value: _fmt(job.appliedAt)),
                          const SizedBox(height: 6),
                          _DateChip(label: 'Modified', value: _fmt(job.updatedAt)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Status + content card ──────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatusBadge(status: job.status),
                      const SizedBox(height: 16),
                      _ActionRow(
                          icon: Icons.notes_rounded,
                          label: 'Detail Notes',
                          value: job.notes?.isNotEmpty == true
                              ? job.notes!
                              : 'No detail notes yet'),
                      if (job.url != null && job.url!.isNotEmpty)
                        _ActionRow(
                            icon: Icons.open_in_new_rounded,
                            label: 'Job URL',
                            value: job.url!,
                            onTap: () => _launchExternal(job.url!)),
                      if (job.resumePath != null &&
                          job.resumePath!.isNotEmpty)
                        _ActionRow(
                            icon: Icons.description_outlined,
                            label: 'Uploaded Resume',
                            value: job.resumePath!.split('/').last,
                            onTap: () => _openResume(context, job.resumePath!)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── Action row ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_comment_outlined, size: 18),
                        label: const Text('Comment'),
                        onPressed: () => _showNoteDialog(context, job),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                        label: const Text('Update Status'),
                        onPressed: () => _showStatusSheet(context, job),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _TimelineCard(
                    title: 'Comment History', entries: job.noteTimeline),
                const SizedBox(height: 24),

                // ── Edit + Delete ─────────────────────────────────────────
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
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.red),
                      onPressed: () => _confirmDelete(context, job),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  // Modern status selector — bottom sheet with interactive cards
  void _showStatusSheet(BuildContext context, Job job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => _StatusSelectorSheet(
        currentStatus: job.status,
        onSelected: (selected) async {
          final actions = await ref.read(jobActionsProvider.future);
          await actions.changeStatus(
              job, selected, DateTime.now().millisecondsSinceEpoch);
          if (sheetCtx.mounted) Navigator.of(sheetCtx).pop();
        },
      ),
    );
  }

  Future<void> _launchExternal(String value) async {
    final uri = Uri.tryParse(
        value.startsWith('http') ? value : 'https://$value');
    if (uri != null) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openResume(BuildContext context, String path) {
    final file = File(path);
    if (!file.existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File not available or moved'),
          backgroundColor: Colors.orange));
      return;
    }
    Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => _FileViewerPage(path: path)));
  }

  void _showNoteDialog(BuildContext context, Job job) {
    final note = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Add Comment'),
        content: TextField(
            controller: note,
            decoration:
                const InputDecoration(labelText: 'Daily comment'),
            maxLines: 4,
            autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () async {
                if (note.text.trim().isEmpty) return;
                final actions = await ref.read(jobActionsProvider.future);
                await actions.appendNote(
                    job,
                    JobTimelineEntry(
                        date: DateTime.now().millisecondsSinceEpoch,
                        text: note.text.trim()));
                if (dialogCtx.mounted) Navigator.of(dialogCtx).pop();
              },
              child: const Text('Save')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, Job job) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Delete job?'),
        content:
            Text('Remove "${job.title}" at ${job.company}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () async {
                Navigator.of(dialogCtx).pop();
                final actions = await ref.read(jobActionsProvider.future);
                await actions.deleteJob(job);
                if (context.mounted) context.pop();
              },
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}

// ── Modern status selector sheet ───────────────────────────────────────────────
class _StatusSelectorSheet extends StatefulWidget {
  final String currentStatus;
  final Future<void> Function(String) onSelected;

  const _StatusSelectorSheet(
      {required this.currentStatus, required this.onSelected});

  @override
  State<_StatusSelectorSheet> createState() => _StatusSelectorSheetState();
}

class _StatusSelectorSheetState extends State<_StatusSelectorSheet> {
  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentStatus;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text('Update Status',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          ...List.generate(_kStatuses.length, (i) {
            final s = _kStatuses[i];
            final color = _kStatusColors[s]!;
            final isSelected = _selected == s;
            return GestureDetector(
              onTap: () => setState(() => _selected = s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: isSelected ? color : Theme.of(context).dividerColor,
                      width: isSelected ? 2 : 1),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                          color: isSelected
                              ? color
                              : color.withValues(alpha: 0.12),
                          shape: BoxShape.circle),
                      child: Icon(_kStatusIcons[s],
                          size: 18,
                          color: isSelected ? Colors.white : color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(_kLabels[s]!,
                          style: GoogleFonts.inter(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              fontSize: 15,
                              color: isSelected
                                  ? color
                                  : Theme.of(context).colorScheme.onSurface)),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle_rounded,
                          color: color, size: 22),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _saving
                ? null
                : () async {
                    if (_selected == widget.currentStatus) {
                      Navigator.of(context).pop();
                      return;
                    }
                    setState(() => _saving = true);
                    await widget.onSelected(_selected);
                  },
            style: FilledButton.styleFrom(backgroundColor: _mc),
            child: Text(_saving ? 'Saving…' : 'Confirm Status'),
          ),
        ],
      ),
    );
  }
}

// ── Date chip helper ──────────────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  const _DateChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                fontSize: 10,
                color: Theme.of(context).hintColor,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(value,
            style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface),
            maxLines: 1),
      ],
    );
  }
}

// ── File viewer (PDF + image, with missing-file guard) ────────────────────────
class _FileViewerPage extends StatelessWidget {
  final String path;
  const _FileViewerPage({required this.path});

  @override
  Widget build(BuildContext context) {
    final lower = path.toLowerCase();
    final isPdf = lower.endsWith('.pdf');
    final isImage = lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');

    Widget body;
    if (isPdf) {
      body = SfPdfViewer.file(File(path));
    } else if (isImage) {
      body = InteractiveViewer(
          child: Center(
              child: Image.file(File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => _unavailable(context))));
    } else {
      // Other doc types — hand off to external app
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final uri = Uri.file(path);
        final ok = await launchUrl(uri,
            mode: LaunchMode.externalApplication);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Cannot preview this file. Open with another application?')));
        }
        if (context.mounted) Navigator.of(context).pop();
      });
      body = const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: Text(path.split('/').last)),
      body: body,
    );
  }

  Widget _unavailable(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.broken_image_outlined,
              size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text('File not available or moved',
              style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}

// ── Detail row helper ──────────────────────────────────────────────────────────
class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _ActionRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon, color: AndroidTheme.primary),
        title: Text(label,
            style: GoogleFonts.inter(
                fontSize: 12, color: Theme.of(context).hintColor)),
        subtitle: Text(value,
            style: GoogleFonts.inter(
                fontSize: 14,
                color: onTap == null
                    ? Theme.of(context).colorScheme.onSurface
                    : AndroidTheme.primary)),
        onTap: onTap,
      );
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _kStatusColors[status] ?? Theme.of(context).hintColor;
    return Chip(
      avatar:
          Icon(_kStatusIcons[status] ?? Icons.circle, size: 16, color: color),
      label: Text(_kLabels[status] ?? status),
      backgroundColor: color.withValues(alpha: 0.12),
      labelStyle:
          GoogleFonts.inter(color: color, fontWeight: FontWeight.w700),
      side: BorderSide.none,
    );
  }
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
            Text(title,
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 12),
            if (entries.isEmpty)
              Text('No history yet',
                  style:
                      GoogleFonts.inter(color: Theme.of(context).hintColor))
            else
              ...entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_JobDetailsScreenState._fmt(e.date),
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Theme.of(context).hintColor,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(e.text,
                                  style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Theme.of(context).colorScheme.onSurface))),
                        ]),
                  )),
          ],
        ),
      );
}