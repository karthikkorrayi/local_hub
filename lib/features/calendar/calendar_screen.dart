import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/day_entry.dart';
import '../../data/models/week_todo.dart';
import '../../data/models/job.dart';
import 'calendar_provider.dart';

// ── Category metadata ──────────────────────────────────────────────────────────
const _kCategories = ['payment', 'ticket', 'planning', 'free', 'other'];
const _kCategoryLabels = {
  'payment':  '💳 Payment',
  'ticket':   '🎟 Ticket',
  'planning': '📋 Planning',
  'free':     '🕐 Free Time',
  'other':    '📌 Other',
};
const _kCategoryColors = {
  'payment':  Color(0xFFE53935),
  'ticket':   Color(0xFF8E24AA),
  'planning': Color(0xFF1E88E5),
  'free':     Color(0xFF43A047),
  'other':    Color(0xFF757575),
};

const _kMoods = ['😊', '😐', '😓', '🔥', '💼', '😴', '🎯', '💪'];

// ── Screen ─────────────────────────────────────────────────────────────────────
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMonthView = ref.watch(calendarViewProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          // View toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true,  label: Text('Month')),
              ButtonSegment(value: false, label: Text('Week')),
            ],
            selected: {isMonthView},
            onSelectionChanged: (s) =>
                ref.read(calendarViewProvider.notifier).state = s.first,
            style: const ButtonStyle(
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Event',
            onPressed: () => _showEventForm(context, ref),
          ),
        ],
      ),
      body: isWide
          ? _WideLayout(isMonthView: isMonthView)
          : _NarrowLayout(isMonthView: isMonthView),
    );
  }

  void _showEventForm(BuildContext context, WidgetRef ref,
      {CalendarEvent? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EventFormSheet(ref: ref, existing: existing),
    );
  }
}

// ── Wide layout: calendar left, detail right ───────────────────────────────────
class _WideLayout extends ConsumerWidget {
  final bool isMonthView;
  const _WideLayout({required this.isMonthView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 380,
          child: _CalendarPanel(isMonthView: isMonthView),
        ),
        const VerticalDivider(width: 1),
        Expanded(
          child: _DayDetailPanel(
            onEditEvent: (e) => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _EventFormSheet(ref: ref, existing: e),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Narrow layout: calendar top, detail below ──────────────────────────────────
class _NarrowLayout extends ConsumerWidget {
  final bool isMonthView;
  const _NarrowLayout({required this.isMonthView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _CalendarPanel(isMonthView: isMonthView),
        const Divider(height: 1),
        Expanded(
          child: _DayDetailPanel(
            onEditEvent: (e) => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              builder: (_) => _EventFormSheet(ref: ref, existing: e),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Calendar panel (month or week grid) ───────────────────────────────────────
class _CalendarPanel extends ConsumerWidget {
  final bool isMonthView;
  const _CalendarPanel({required this.isMonthView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final monthEvents = ref.watch(monthEventsProvider).valueOrNull ?? {};

    return TableCalendar(
      firstDay: DateTime(2020),
      lastDay: DateTime(2030),
      focusedDay: selected,
      calendarFormat:
          isMonthView ? CalendarFormat.month : CalendarFormat.week,
      selectedDayPredicate: (day) => isSameDay(day, selected),
      onDaySelected: (selectedDay, focusedDay) {
        ref.read(selectedDayProvider.notifier).state = selectedDay;
      },
      onPageChanged: (focusedDay) {
        ref.read(selectedDayProvider.notifier).state = focusedDay;
      },
      eventLoader: (day) {
        final key = dateKey(day);
        return monthEvents[key] ?? [];
      },
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        markerDecoration: const BoxDecoration(
          color: Color(0xFFE53935),
          shape: BoxShape.circle,
        ),
      ),
      headerStyle: const HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
      ),
    );
  }
}

// ── Day detail panel ───────────────────────────────────────────────────────────
class _DayDetailPanel extends ConsumerWidget {
  final void Function(CalendarEvent) onEditEvent;
  const _DayDetailPanel({required this.onEditEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final eventsAsync = ref.watch(dayEventsProvider);
    final entryAsync = ref.watch(dayEntryProvider);
    final todosAsync = ref.watch(weekTodosProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Date header
        Text(
          _formatDate(selected),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Mood + diary section
        _MoodDiarySection(entryAsync: entryAsync),
        const SizedBox(height: 16),

        // Week todos section
        _WeekTodoSection(todosAsync: todosAsync),
        const SizedBox(height: 16),

        // Events section
        _EventsSection(
          eventsAsync: eventsAsync,
          onEdit: onEditEvent,
        ),
      ],
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      '', 'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[d.weekday]}, ${months[d.month]} ${d.day}';
  }
}

// ── Mood + diary ───────────────────────────────────────────────────────────────
class _MoodDiarySection extends ConsumerStatefulWidget {
  final AsyncValue<DayEntry?> entryAsync;
  const _MoodDiarySection({required this.entryAsync});

  @override
  ConsumerState<_MoodDiarySection> createState() => _MoodDiarySectionState();
}

class _MoodDiarySectionState extends ConsumerState<_MoodDiarySection> {
  late TextEditingController _diary;
  String? _selectedMood;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _diary = TextEditingController();
  }

  @override
  void didUpdateWidget(_MoodDiarySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.entryAsync.whenData((entry) {
      if (entry != null) {
        _selectedMood = entry.mood;
        if (_diary.text != (entry.diary ?? '')) {
          _diary.text = entry.diary ?? '';
        }
      } else {
        _selectedMood = null;
        _diary.clear();
      }
    });
  }

  @override
  void dispose() {
    _diary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final selected = ref.read(selectedDayProvider);
    final actions = await ref.read(calendarActionsProvider.future);
    final entry = DayEntry(
      id: ref.read(dayEntryProvider).valueOrNull?.id ?? const Uuid().v4(),
      date: dateKey(selected),
      mood: _selectedMood,
      diary: _diary.text.trim().isEmpty ? null : _diary.text.trim(),
    );
    await actions.saveDayEntry(entry);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Mood & Diary',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(
                  icon: Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () =>
                      setState(() => _expanded = !_expanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Mood picker
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _kMoods.map((emoji) {
                final selected = _selectedMood == emoji;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedMood =
                        selected ? null : emoji);
                    _save();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppTheme.primary.withValues(alpha: 0.15)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: selected
                          ? Border.all(color: AppTheme.primary)
                          : null,
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 22)),
                  ),
                );
              }).toList(),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _diary,
                decoration: const InputDecoration(
                  hintText: 'Write your diary note for today…',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                onChanged: (_) => _save(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Week todos ─────────────────────────────────────────────────────────────────
class _WeekTodoSection extends ConsumerStatefulWidget {
  final AsyncValue<List<WeekTodo>> todosAsync;
  const _WeekTodoSection({required this.todosAsync});

  @override
  ConsumerState<_WeekTodoSection> createState() => _WeekTodoSectionState();
}

class _WeekTodoSectionState extends ConsumerState<_WeekTodoSection> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addTodo() async {
    if (_controller.text.trim().isEmpty) return;
    final selected = ref.read(selectedDayProvider);
    final actions = await ref.read(calendarActionsProvider.future);
    await actions.addTodo(WeekTodo(
      id: const Uuid().v4(),
      weekStart: weekStartKey(selected),
      title: _controller.text.trim(),
      isDone: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final todos = widget.todosAsync.valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('This Week\'s Todos',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...todos.map((todo) => _TodoTile(todo: todo)),
            // Add todo input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Add a todo for this week…',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTodo(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: _addTodo,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoTile extends ConsumerWidget {
  final WeekTodo todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Checkbox(
          value: todo.isDone,
          onChanged: (_) async {
            final actions =
                await ref.read(calendarActionsProvider.future);
            await actions.toggleTodo(todo);
          },
        ),
        Expanded(
          child: Text(
            todo.title,
            style: TextStyle(
              decoration:
                  todo.isDone ? TextDecoration.lineThrough : null,
              color: todo.isDone ? Colors.grey : null,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 16),
          color: Colors.grey.shade400,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () async {
            final actions =
                await ref.read(calendarActionsProvider.future);
            await actions.deleteTodo(todo);
          },
        ),
      ],
    );
  }
}

// ── Events section ─────────────────────────────────────────────────────────────
class _EventsSection extends ConsumerWidget {
  final AsyncValue<List<CalendarEvent>> eventsAsync;
  final void Function(CalendarEvent) onEdit;
  const _EventsSection(
      {required this.eventsAsync, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = eventsAsync.valueOrNull ?? [];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Events',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            if (events.isEmpty)
              Text('No events for this day',
                  style: TextStyle(
                      color: Colors.grey.shade400, fontSize: 13))
            else
              ...events.map((e) => _EventTile(
                    event: e,
                    onEdit: onEdit,
                  )),
          ],
        ),
      ),
    );
  }
}

class _EventTile extends ConsumerWidget {
  final CalendarEvent event;
  final void Function(CalendarEvent) onEdit;
  const _EventTile({required this.event, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        _kCategoryColors[event.category] ?? const Color(0xFF757575);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(event.title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (event.startTime != null)
            Text('${event.startTime} ${event.endTime != null ? '→ ${event.endTime}' : ''}',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12)),
          if (event.linkedJobTitle != null)
            Text('🔗 ${event.linkedJobTitle}',
                style: TextStyle(
                    color: AppTheme.primary, fontSize: 12)),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _kCategoryLabels[event.category] ?? event.category,
              style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 16),
            color: Colors.grey.shade400,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      onTap: () => onEdit(event),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete event?'),
        content: Text('Remove "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              final actions =
                  await ref.read(calendarActionsProvider.future);
              await actions.deleteEvent(event);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Event form ─────────────────────────────────────────────────────────────────
class _EventFormSheet extends StatefulWidget {
  final WidgetRef ref;
  final CalendarEvent? existing;
  const _EventFormSheet({required this.ref, this.existing});

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;
  late String _category;
  Job? _linkedJob;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title       = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _startTime   = TextEditingController(text: e?.startTime ?? '');
    _endTime     = TextEditingController(text: e?.endTime ?? '');
    _category    = e?.category ?? 'other';
  }

  @override
  void dispose() {
    _title.dispose(); _description.dispose();
    _startTime.dispose(); _endTime.dispose();
    super.dispose();
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      ctrl.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final selected = widget.ref.read(selectedDayProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = widget.existing;

    final event = CalendarEvent(
      id:             existing?.id ?? const Uuid().v4(),
      title:          _title.text.trim(),
      description:    _description.text.trim().isEmpty ? null : _description.text.trim(),
      date:           dateKey(selected),
      startTime:      _startTime.text.trim().isEmpty ? null : _startTime.text.trim(),
      endTime:        _endTime.text.trim().isEmpty ? null : _endTime.text.trim(),
      category:       _category,
      linkedJobId:    _linkedJob?.id,
      linkedJobTitle: _linkedJob?.title,
      createdAt:      existing?.createdAt ?? now,
    );

    final actions = await widget.ref.read(calendarActionsProvider.future);
    if (existing == null) {
      await actions.addEvent(event);
    } else {
      await actions.updateEvent(event);
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final jobsAsync = widget.ref.watch(allJobsForPickerProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(isEdit ? 'Edit Event' : 'Add Event',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Title *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _kCategories
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(_kCategoryLabels[c]!),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v ?? _category),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _startTime,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Start time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () => _pickTime(_startTime),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _endTime,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'End time',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.access_time),
                    ),
                    onTap: () => _pickTime(_endTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // Job linkage picker
            jobsAsync.when(
              data: (jobs) => jobs.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<Job?>(
                      value: _linkedJob,
                      decoration: const InputDecoration(
                        labelText: '🔗 Link to Job (reminder)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                            value: null, child: Text('None')),
                        ...jobs.map((j) => DropdownMenuItem(
                              value: j,
                              child: Text(
                                '${j.title} @ ${j.company}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )),
                      ],
                      onChanged: (v) => setState(() => _linkedJob = v),
                    ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Saving…'
                  : isEdit
                      ? 'Save Changes'
                      : 'Add Event'),
            ),
          ],
        ),
      ),
    );
  }
}