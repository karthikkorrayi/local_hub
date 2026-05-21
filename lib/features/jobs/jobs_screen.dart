import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/job.dart';
import 'job_provider.dart';

// ── Column metadata ────────────────────────────────────────────────────────────
const _kStatuses = ['wishlist', 'applied', 'interview', 'offer', 'rejected'];
const _kLabels = {
  'wishlist':  'Wishlist',
  'applied':   'Applied',
  'interview': 'Interview',
  'offer':     'Offer',
  'rejected':  'Rejected',
};

// ── Screen ─────────────────────────────────────────────────────────────────────
class JobsScreen extends ConsumerWidget {
  const JobsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final columns = ref.watch(kanbanColumnsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Job',
            onPressed: () => _showJobForm(context, ref),
          ),
        ],
      ),
      body: isWide
          ? _WideKanban(columns: columns, onEdit: (job) => _showJobForm(context, ref, existing: job))
          : _NarrowKanban(columns: columns, onEdit: (job) => _showJobForm(context, ref, existing: job)),
    );
  }

  void _showJobForm(BuildContext context, WidgetRef ref, {Job? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _JobFormSheet(ref: ref, existing: existing),
    );
  }
}

// ── Wide layout: horizontal scrolling lanes ────────────────────────────────────
class _WideKanban extends StatelessWidget {
  final Map<String, List<Job>> columns;
  final void Function(Job) onEdit;
  const _WideKanban({required this.columns, required this.onEdit});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(16),
      itemCount: _kStatuses.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (_, i) {
        final status = _kStatuses[i];
        return _KanbanColumn(
          status: status,
          jobs: columns[status] ?? [],
          width: 280,
          onEdit: onEdit,
        );
      },
    );
  }
}

// ── Narrow layout: one column at a time via chip switcher ──────────────────────
class _NarrowKanban extends StatefulWidget {
  final Map<String, List<Job>> columns;
  final void Function(Job) onEdit;
  const _NarrowKanban({required this.columns, required this.onEdit});

  @override
  State<_NarrowKanban> createState() => _NarrowKanbanState();
}

class _NarrowKanbanState extends State<_NarrowKanban> {
  String _active = 'applied';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Status chip switcher
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: _kStatuses.map((s) {
              final selected = s == _active;
              return Padding(
                padding: const EdgeInsets.only(right: 8, top: 8),
                child: ChoiceChip(
                  label: Text(_kLabels[s]!),
                  selected: selected,
                  selectedColor: AppTheme.statusColor(s).withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _active = s),
                ),
              );
            }).toList(),
          ),
        ),
        // Active column fills remaining space
        Expanded(
          child: _KanbanColumn(
            status: _active,
            jobs: widget.columns[_active] ?? [],
            width: double.infinity,
            onEdit: widget.onEdit,
          ),
        ),
      ],
    );
  }
}

// ── Shared column widget ────────────────────────────────────────────────────────
class _KanbanColumn extends ConsumerWidget {
  final String status;
  final List<Job> jobs;
  final double width;
  final void Function(Job) onEdit;

  const _KanbanColumn({
    required this.status,
    required this.jobs,
    required this.width,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = AppTheme.statusColor(status);

    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  _kLabels[status]!,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${jobs.length}',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // Job cards
          Expanded(
            child: jobs.isEmpty
                ? Center(
                    child: Text(
                      'No jobs here',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: jobs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) => _JobCard(
                      job: jobs[i],
                      onEdit: onEdit,
                    ),
                  ),
          ),
        ],
      ),
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
    final color = AppTheme.statusColor(job.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onEdit(job),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                job.company,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              if (job.notes != null && job.notes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  job.notes!,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _kLabels[job.status]!,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    color: Colors.grey.shade400,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete job?'),
        content: Text('Remove "${job.title}" at ${job.company}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(), // dialog only
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop(); // dialog only
              final actions = await ref.read(jobActionsProvider.future);
              await actions.deleteJob(job);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Add / Edit form ────────────────────────────────────────────────────────────
class _JobFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final Job? existing;
  const _JobFormSheet({required this.ref, this.existing});

  @override
  State<_JobFormSheet> createState() => _JobFormSheetState();
}

class _JobFormSheetState extends State<_JobFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _company;
  late final TextEditingController _notes;
  late final TextEditingController _url;
  late String _status;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final j = widget.existing;
    _title   = TextEditingController(text: j?.title ?? '');
    _company = TextEditingController(text: j?.company ?? '');
    _notes   = TextEditingController(text: j?.notes ?? '');
    _url     = TextEditingController(text: j?.url ?? '');
    _status  = j?.status ?? 'applied';
  }

  @override
  void dispose() {
    _title.dispose(); _company.dispose();
    _notes.dispose(); _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _company.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = widget.existing;
    final job = Job(
      id:        existing?.id ?? const Uuid().v4(),
      title:     _title.text.trim(),
      company:   _company.text.trim(),
      status:    _status,
      notes:     _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      url:       _url.text.trim().isEmpty ? null : _url.text.trim(),
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    final actions = await widget.ref.read(jobActionsProvider.future);
    if (existing == null) {
      await actions.addJob(job);
    } else {
      await actions.updateJob(job);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24, 24, 24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            isEdit ? 'Edit Job' : 'Add Job',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            decoration: const InputDecoration(
              labelText: 'Job title *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _company,
            decoration: const InputDecoration(
              labelText: 'Company *',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _status,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
            items: _kStatuses.map((s) => DropdownMenuItem(
              value: s,
              child: Text(_kLabels[s]!),
            )).toList(),
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notes,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _url,
            decoration: const InputDecoration(
              labelText: 'Job URL',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving…' : isEdit ? 'Save Changes' : 'Add Job'),
          ),
        ],
      ),
    );
  }
}