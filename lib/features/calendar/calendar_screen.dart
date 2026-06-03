import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/android_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/day_entry.dart';
import '../../data/models/wishlist_item.dart';
import '../wishlist/wishlist_provider.dart';
import 'calendar_provider.dart';

const _eventCategories = ['travel', 'movie', 'occasion'];
const _categoryLabels = {
  'travel':   'Travel',
  'movie':    'Movie',
  'occasion': 'Occasion',
  'birthday': 'Birthday',
  'task':     'Task',
};
const _categoryColors = {
  'travel':   Color(0xFFE0F2FE),
  'movie':    Color(0xFFF3E8FF),
  'occasion': Color(0xFFFFE4E6),
  'birthday': Color(0xFFFFF7ED),
  'task':     Color(0xFFDCFCE7),
};
const _categoryIconData = {
  'travel':   Icons.flight_rounded,
  'movie':    Icons.movie_outlined,
  'occasion': Icons.celebration_outlined,
  'birthday': Icons.cake_outlined,
  'task':     Icons.task_alt_rounded,
};
const _moods = ['😀', '🥰', '😌', '😔', '😴', '🤔'];

// ── Screen ─────────────────────────────────────────────────────────────────────
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view        = ref.watch(calendarViewProvider);
    final selectedDay = dayOnly(ref.watch(selectedDayProvider));
    final today       = dayOnly(DateTime.now());
    final isToday     = selectedDay == today;

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: Text('Calendar',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
        children: [
          const _CalendarCard(),
          const SizedBox(height: 12),
          const _SelectedDayPanel(),
          const SizedBox(height: 12),
          _FilterBar(view: view),
          const SizedBox(height: 12),
          const _ActivitySection(),
        ],
      ),
    );
  }
}

// ── Calendar card ──────────────────────────────────────────────────────────────
class _CalendarCard extends ConsumerWidget {
  const _CalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused  = ref.watch(focusedMonthProvider);
    final selected = ref.watch(selectedDayProvider);
    final eventMap = ref.watch(monthEventsProvider).valueOrNull ?? {};
    final entries  = ref.watch(monthMoodProvider).valueOrNull ?? {};

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(children: [
        Row(children: [
          TextButton.icon(
            onPressed: () => _pickMonth(context, ref, focused),
            icon: const Icon(Icons.expand_more_rounded),
            label: Text(_monthTitle(focused),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const Spacer(),
          OutlinedButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDayProvider.notifier).state = now;
              ref.read(focusedMonthProvider.notifier).state =
                  DateTime(now.year, now.month);
            },
            child: const Text('Today'),
          ),
        ]),
        TableCalendar<CalendarEvent>(
          firstDay: DateTime(2020),
          lastDay: DateTime(2035),
          focusedDay: focused,
          selectedDayPredicate: (d) => isSameDay(d, selected),
          headerVisible: false,
          rowHeight: 72,
          daysOfWeekHeight: 28,
          calendarFormat: CalendarFormat.month,
          onDaySelected: (day, focus) {
            ref.read(selectedDayProvider.notifier).state = day;
            ref.read(focusedMonthProvider.notifier).state =
                DateTime(focus.year, focus.month);
          },
          onPageChanged: (focus) =>
              ref.read(focusedMonthProvider.notifier).state =
                  DateTime(focus.year, focus.month),
          eventLoader: (day) => eventMap[dateKey(day)] ?? const [],
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (ctx, day, _) => _DayCell(
                day: day,
                events: eventMap[dateKey(day)] ?? const [],
                entry: entries[dateKey(day)]),
            todayBuilder: (ctx, day, _) => _DayCell(
                day: day,
                isToday: true,
                events: eventMap[dateKey(day)] ?? const [],
                entry: entries[dateKey(day)]),
            selectedBuilder: (ctx, day, _) => _DayCell(
                day: day,
                isSelected: true,
                events: eventMap[dateKey(day)] ?? const [],
                entry: entries[dateKey(day)]),
            markerBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ]),
    );
  }

  // FIX: use dialogCtx — not outer context — to avoid blank screen
  Future<void> _pickMonth(
      BuildContext context, WidgetRef ref, DateTime focused) async {
    final year = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Select year'),
        content: SizedBox(
          width: 320,
          height: 320,
          child: YearPicker(
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
            selectedDate: focused,
            onChanged: (d) => Navigator.of(dialogCtx).pop(d.year),
          ),
        ),
      ),
    );
    if (year == null || !context.mounted) return;

    final month = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Select month'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(
            12,
            (i) => ChoiceChip(
              label: Text(_months[i + 1]),
              selected: focused.month == i + 1,
              onSelected: (_) => Navigator.of(dialogCtx).pop(i + 1),
            ),
          ),
        ),
      ),
    );
    if (month == null || !context.mounted) return;

    final d = DateTime(year, month);
    ref.read(focusedMonthProvider.notifier).state = d;
    ref.read(selectedDayProvider.notifier).state = d;
  }
}

// ── Day cell ───────────────────────────────────────────────────────────────────
class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final bool isSelected;
  final List<CalendarEvent> events;
  final DayEntry? entry;

  const _DayCell({
    required this.day,
    this.isToday = false,
    this.isSelected = false,
    required this.events,
    this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final dots = events.take(3).toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isSelected
            ? AndroidTheme.primary.withValues(alpha: .14)
            : isToday
                ? AndroidTheme.primary.withValues(alpha: .07)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected ? Border.all(color: AndroidTheme.primary) : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('${day.day}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 2),
        // Only show mood emoji here (diary) — no category emojis on calendar dates
        if (entry?.mood != null)
          Text(entry!.mood!, style: const TextStyle(fontSize: 14))
        else
          const SizedBox(height: 14),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots
              .map((e) => Container(
                    width: 5,
                    height: 5,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                        color: _dotColor(e), shape: BoxShape.circle),
                  ))
              .toList(),
        ),
      ]),
    );
  }

  Color _dotColor(CalendarEvent e) => e.itemType == 'task'
      ? Colors.green
      : e.itemType == 'birthday'
          ? Colors.orange
          : Colors.blue;
}

// ── Selected day panel ─────────────────────────────────────────────────────────
class _SelectedDayPanel extends ConsumerWidget {
  const _SelectedDayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day      = dayOnly(ref.watch(selectedDayProvider));
    final today    = dayOnly(DateTime.now());
    final isToday  = day == today;
    final isPast   = day.isBefore(today);
    final isFuture = day.isAfter(today);

    final events = ref.watch(dayEventsProvider).valueOrNull ?? [];
    final entry  = ref.watch(dayEntryProvider).valueOrNull;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date + contextual add button
          Row(
            children: [
              Expanded(
                child: Text(
                  _fullDate(day),
                  style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (!isPast)
                GestureDetector(
                  onTap: () => _showAddMenu(context, ref, day,
                      isToday: isToday),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: AndroidTheme.primary,
                        shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded,
                        size: 20, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Diary — editable today, read-only past
          if (isToday) _DiaryEditor(entry: entry),
          if (isPast && entry != null) _DiaryPreview(entry: entry),
          if (isToday || isPast) const SizedBox(height: 12),

          // Events/tasks for the day
          _DayEventList(events: events, readOnly: isPast),
        ],
      ),
    );
  }

  void _showAddMenu(
    BuildContext context,
    WidgetRef ref,
    DateTime day, {
    required bool isToday,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AndroidTheme.divider,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text('Add to ${_fullDate(day)}',
                  style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 8),
              if (isToday)
                ListTile(
                  leading: const Icon(Icons.book_outlined,
                      color: AndroidTheme.primary),
                  title: Text('Diary Note',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Diary is shown above ↑'),
                          duration: Duration(seconds: 2)),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.task_alt_rounded,
                    color: AndroidTheme.primary),
                title: Text('Add Task',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showTaskDialog(context, ref, day);
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_outlined,
                    color: AndroidTheme.primary),
                title: Text('Add Event',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showEventSheet(context, ref, day);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cake_outlined,
                    color: AndroidTheme.primary),
                title: Text('Add Birthday',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _showBirthdaySheet(context, ref, day);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Diary editor (today only) ──────────────────────────────────────────────────
class _DiaryEditor extends ConsumerStatefulWidget {
  final DayEntry? entry;
  const _DiaryEditor({this.entry});

  @override
  ConsumerState<_DiaryEditor> createState() => _DiaryEditorState();
}

class _DiaryEditorState extends ConsumerState<_DiaryEditor> {
  late String _mood;
  late TextEditingController _diary;

  @override
  void initState() {
    super.initState();
    _mood  = widget.entry?.mood ?? _moods.first;
    _diary = TextEditingController(text: widget.entry?.diary ?? '');
  }

  @override
  void dispose() {
    _diary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Today\'s Diary',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 8),
        // Mood row — emoji chips are intentional here (diary mood)
        Wrap(
          spacing: 6,
          children: _moods
              .map((m) => ChoiceChip(
                    label: Text(m),
                    selected: _mood == m,
                    onSelected: (_) => setState(() => _mood = m),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _diary,
          maxLines: 2,
          decoration:
              const InputDecoration(labelText: 'Short diary note'),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            icon: const Icon(Icons.save_outlined, size: 16),
            label: const Text('Save'),
            onPressed: () async {
              final day     = ref.read(selectedDayProvider);
              final actions =
                  await ref.read(calendarActionsProvider.future);
              await actions.saveDayEntry(DayEntry(
                id:    widget.entry?.id ?? const Uuid().v4(),
                date:  dateKey(day),
                mood:  _mood,
                diary: _diary.text.trim().isEmpty
                    ? null
                    : _diary.text.trim(),
              ));
            },
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ── Diary preview (past) ───────────────────────────────────────────────────────
class _DiaryPreview extends StatelessWidget {
  final DayEntry entry;
  const _DiaryPreview({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Diary',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AndroidTheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${entry.mood ?? ''} ${entry.diary ?? 'No diary note'.trim()}',
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        const Divider(height: 24),
      ],
    );
  }
}

// ── Day event list ─────────────────────────────────────────────────────────────
class _DayEventList extends ConsumerWidget {
  final List<CalendarEvent> events;
  final bool readOnly;
  const _DayEventList({required this.events, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (events.isEmpty) {
      return Text('Nothing scheduled.',
          style: GoogleFonts.inter(
              color: AndroidTheme.textTertiary, fontSize: 13));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: events
          .map((e) => _EventTile(event: e, readOnly: readOnly))
          .toList(),
    );
  }
}

// ── Event tile ─────────────────────────────────────────────────────────────────
class _EventTile extends ConsumerWidget {
  final CalendarEvent event;
  final bool readOnly;
  const _EventTile({required this.event, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type  = event.itemType ?? event.category;
    final color = _categoryColors[type] ?? AndroidTheme.surface;
    final icon  = _categoryIconData[type] ?? Icons.event_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (event.itemType == 'task')
            Checkbox(
              value: event.isDone,
              onChanged: readOnly
                  ? null
                  : (_) async {
                      final a =
                          await ref.read(calendarActionsProvider.future);
                      await a.toggleEventDone(event);
                    },
              visualDensity: VisualDensity.compact,
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: 18, color: AndroidTheme.textSecondary),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.title,
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        decoration: event.isDone
                            ? TextDecoration.lineThrough
                            : null)),
                if (event.description?.isNotEmpty == true)
                  Text(event.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AndroidTheme.textSecondary)),
                Text(_categoryLabels[type] ?? type,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AndroidTheme.textTertiary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final String view;
  const _FilterBar({required this.view});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filters = [
      ('Today',      'day'),
      ('This Week',  'week'),
      ('This Month', 'month'),
    ];
    return Row(
      children: filters.map((f) {
        final isSelected = view == f.$2;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(f.$1),
            selected: isSelected,
            onSelected: (_) =>
                ref.read(calendarViewProvider.notifier).state = f.$2,
          ),
        );
      }).toList(),
    );
  }
}

// ── Activity section ───────────────────────────────────────────────────────────
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    final events = view == 'month'
        ? ref.watch(monthEventListProvider).valueOrNull ?? []
        : view == 'week'
            ? ref.watch(weekEventsProvider).valueOrNull ?? []
            : ref.watch(dayEventsProvider).valueOrNull ?? [];

    final tasks     = events.where((e) => e.itemType == 'task').toList();
    final eventsAll = events
        .where((e) => e.itemType == 'event')
        .toList();
    final birthdays = events.where((e) => e.itemType == 'birthday').toList();

    final hasContent =
        tasks.isNotEmpty || eventsAll.isNotEmpty || birthdays.isNotEmpty;

    if (!hasContent) return const SizedBox.shrink();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tasks.isNotEmpty) ...[
            _SectionHeader(icon: Icons.task_alt_rounded, label: 'Tasks'),
            const SizedBox(height: 8),
            ...tasks.map((e) => _EventTile(event: e)),
            if (eventsAll.isNotEmpty || birthdays.isNotEmpty)
              const SizedBox(height: 14),
          ],
          if (eventsAll.isNotEmpty) ...[
            _SectionHeader(icon: Icons.event_outlined, label: 'Events'),
            const SizedBox(height: 8),
            ...eventsAll.map((e) => _EventTile(event: e)),
            if (birthdays.isNotEmpty) const SizedBox(height: 14),
          ],
          if (birthdays.isNotEmpty) ...[
            _SectionHeader(icon: Icons.cake_outlined, label: 'Birthdays'),
            const SizedBox(height: 8),
            ...birthdays.map((e) => _EventTile(event: e)),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionHeader({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AndroidTheme.primary),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}

// ── Add task dialog ────────────────────────────────────────────────────────────
void _showTaskDialog(BuildContext context, WidgetRef ref, DateTime day) {
  final title = TextEditingController();
  final desc  = TextEditingController();
  showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: const Text('Add Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: title,
              decoration:
                  const InputDecoration(labelText: 'Task title')),
          TextField(
              controller: desc,
              decoration:
                  const InputDecoration(labelText: 'Description (optional)')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              final a = await ref.read(calendarActionsProvider.future);
              await a.addEvent(CalendarEvent(
                id:          const Uuid().v4(),
                title:       title.text.trim(),
                description: desc.text.trim().isEmpty
                    ? null
                    : desc.text.trim(),
                date:        dateKey(day),
                category:    'task',
                itemType:    'task',
                isDone:      false,
                createdAt:   DateTime.now().millisecondsSinceEpoch,
              ));
              if (dialogCtx.mounted) Navigator.pop(dialogCtx);
            },
            child: const Text('Add Task')),
      ],
    ),
  );
}

// ── Add event sheet ────────────────────────────────────────────────────────────
void _showEventSheet(BuildContext context, WidgetRef ref, DateTime day) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _EventForm(day: day),
  );
}

class _EventForm extends ConsumerStatefulWidget {
  final DateTime day;
  const _EventForm({required this.day});

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  final _title  = TextEditingController();
  final _notes  = TextEditingController();
  final _movie  = TextEditingController();
  final _seats  = TextEditingController();
  final _screen = TextEditingController();
  final _days   = TextEditingController();
  String _cat = 'travel';
  DateTime? _depart, _arrive, _start;
  String? _ticket;

  @override
  void dispose() {
    _title.dispose(); _notes.dispose(); _movie.dispose();
    _seats.dispose(); _screen.dispose(); _days.dispose();
    super.dispose();
  }

  Future<void> _pickTicket() async {
    const g = XTypeGroup(label: 'Documents',
        extensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx']);
    final f = await openFile(acceptedTypeGroups: [g]);
    // Store only original path — no copy
    if (f != null) setState(() => _ticket = f.path);
  }

  Future<void> _pickDateTime(void Function(DateTime) setValue) async {
    final d = await showDatePicker(
        context: context,
        initialDate: widget.day,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035));
    if (d == null || !mounted) return;
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay.now());
    setValue(DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Event',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
                controller: _title,
                decoration:
                    const InputDecoration(labelText: 'Event Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _cat,
              items: _eventCategories
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(_categoryLabels[c]!)))
                  .toList(),
              onChanged: (v) => setState(() => _cat = v ?? _cat),
              decoration:
                  const InputDecoration(labelText: 'Select Category'),
            ),
            const SizedBox(height: 12),
            if (_cat == 'travel') ...[
              OutlinedButton(
                onPressed: () => _pickDateTime((d) => _depart = d),
                child: Text(_depart == null
                    ? 'Departure Date & Time'
                    : _fullDateTime(_depart!)),
              ),
              OutlinedButton(
                onPressed: () => _pickDateTime((d) => _arrive = d),
                child: Text(_arrive == null
                    ? 'Arrival Date & Time'
                    : _fullDateTime(_arrive!)),
              ),
              TextField(
                  controller: _notes,
                  decoration:
                      const InputDecoration(labelText: 'Details / Notes')),
              OutlinedButton.icon(
                onPressed: _pickTicket,
                icon: const Icon(Icons.attach_file),
                label: Text(_ticket?.split('/').last ??
                    'Attach Ticket (optional)'),
              ),
            ],
            if (_cat == 'movie') ...[
              TextField(
                  controller: _movie,
                  decoration:
                      const InputDecoration(labelText: 'Movie Name')),
              OutlinedButton(
                onPressed: () => _pickDateTime((d) => _start = d),
                child: Text(_start == null
                    ? 'Start Time'
                    : _fullDateTime(_start!)),
              ),
              TextField(
                  controller: _seats,
                  decoration:
                      const InputDecoration(labelText: 'Seat Numbers')),
              TextField(
                  controller: _screen,
                  decoration: const InputDecoration(
                      labelText: 'Screen Number (optional)')),
            ],
            if (_cat == 'occasion') ...[
              TextField(
                controller: _days,
                decoration:
                    const InputDecoration(labelText: 'Number of Days'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                  controller: _notes,
                  decoration: const InputDecoration(
                      labelText: 'Address / Notes (optional)')),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () async {
                if (_title.text.trim().isEmpty) return;
                final details = [
                  if (_cat == 'travel') _notes.text.trim(),
                  if (_cat == 'movie')
                    '${_movie.text.trim()} ${_seats.text.trim()} ${_screen.text.trim()}'
                        .trim(),
                  if (_cat == 'occasion')
                    '${_days.text.trim()} days ${_notes.text.trim()}'.trim(),
                ].where((e) => e.isNotEmpty).join('\n');

                final a = await ref.read(calendarActionsProvider.future);
                await a.addEvent(CalendarEvent(
                  id:          const Uuid().v4(),
                  title:       _title.text.trim(),
                  description: details.isEmpty ? null : details,
                  date:        dateKey(widget.day),
                  startTime:   (_depart ?? _start)?.toIso8601String(),
                  endTime:     _arrive?.toIso8601String(),
                  category:    _cat,
                  itemType:    'event',
                  attachmentPath: _ticket,
                  createdAt:   DateTime.now().millisecondsSinceEpoch,
                ));
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Add Event'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Add birthday sheet ─────────────────────────────────────────────────────────
void _showBirthdaySheet(BuildContext context, WidgetRef ref, DateTime day) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _BirthdayForm(day: day),
  );
}

class _BirthdayForm extends ConsumerStatefulWidget {
  final DateTime day;
  const _BirthdayForm({required this.day});

  @override
  ConsumerState<_BirthdayForm> createState() => _BirthdayFormState();
}

class _BirthdayFormState extends ConsumerState<_BirthdayForm> {
  final _person = TextEditingController();
  final _gift   = TextEditingController();
  final _price  = TextEditingController();
  final _cat    = TextEditingController(text: 'Gift');
  final _url    = TextEditingController();
  bool _idea = false;
  String? _image;
  DateTime? _target;

  @override
  void dispose() {
    _person.dispose(); _gift.dispose(); _price.dispose();
    _cat.dispose(); _url.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    const g = XTypeGroup(label: 'Images',
        extensions: ['jpg', 'jpeg', 'png', 'webp']);
    final f = await openFile(acceptedTypeGroups: [g]);
    // Store only original path — no copy
    if (f != null) setState(() => _image = f.path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add Birthday',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            TextField(
                controller: _person,
                decoration:
                    const InputDecoration(labelText: 'Person Name')),
            SwitchListTile(
              value: _idea,
              onChanged: (v) => setState(() => _idea = v),
              title: Text('Add Gift Idea',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
            if (_idea) ...[
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(
                    _image?.split('/').last ?? 'Add Gift Image'),
              ),
              TextField(
                  controller: _gift,
                  decoration:
                      const InputDecoration(labelText: 'Gift Name')),
              TextField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                  controller: _cat,
                  decoration:
                      const InputDecoration(labelText: 'Category')),
              OutlinedButton(
                onPressed: () async {
                  final d = await showDatePicker(
                      context: context,
                      initialDate: widget.day,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035));
                  if (d != null) setState(() => _target = d);
                },
                child: Text(_target == null
                    ? 'Target Purchase Date'
                    : _fullDate(_target!)),
              ),
              TextField(
                  controller: _url,
                  decoration:
                      const InputDecoration(labelText: 'Product URL')),
            ],
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                if (_person.text.trim().isEmpty) return;
                final personName = _person.text.trim();
                final a = await ref.read(calendarActionsProvider.future);
                await a.addEvent(CalendarEvent(
                  id:        const Uuid().v4(),
                  title:     personName,
                  date:      dateKey(widget.day),
                  category:  'birthday',
                  itemType:  'birthday',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                ));
                // Create gift wishlist item with person + date linked
                if (_idea && _gift.text.trim().isNotEmpty) {
                  final w =
                      await ref.read(wishlistActionsProvider.future);
                  await w.addItem(WishlistItem(
                    id:               const Uuid().v4(),
                    name:             _gift.text.trim(),
                    price:            double.tryParse(_price.text.trim()),
                    imageUrl:         _image,
                    category:         _cat.text.trim().isEmpty
                        ? 'Gift'
                        : 'Gift • ${_cat.text.trim()}',
                    productUrl:       _url.text.trim().isEmpty
                        ? null
                        : _url.text.trim(),
                    targetPurchaseAt: _target?.millisecondsSinceEpoch,
                    isPurchased:      false,
                    createdAt:        DateTime.now().millisecondsSinceEpoch,
                    giftFor:          personName,
                    giftDate:         widget.day.millisecondsSinceEpoch,
                  ));
                }
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save Birthday'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
const _months = [
  '', 'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];
String _monthTitle(DateTime d) => '${_months[d.month]} ${d.year}';
String _fullDate(DateTime d) => '${_months[d.month]} ${d.day}, ${d.year}';
String _fullDateTime(DateTime d) =>
    '${_fullDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';