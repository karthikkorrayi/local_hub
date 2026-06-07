import 'dart:io';
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

const _mc  = AndroidTheme.calendarPrimary;
const _mcl = AndroidTheme.calendarPrimaryLight;

const _categoryLabels = {
  'travel':   'Travel',
  'movie':    'Movie',
  'occasion': 'Occasion',
  'birthday': 'Birthday',
  'task':     'Task',
  'other':    'Other',
};
const _categoryColors = {
  'travel':   Color(0xFFE0F2FE),
  'movie':    Color(0xFFF3E8FF),
  'occasion': Color(0xFFFFE4E6),
  'birthday': Color(0xFFFFF7ED),
  'task':     Color(0xFFDCFCE7),
  'other':    Color(0xFFF1F5F9),
};
const _categoryDarkColors = {
  'travel':   Color(0xFF0A2233),
  'movie':    Color(0xFF1A0A2A),
  'occasion': Color(0xFF2A0A10),
  'birthday': Color(0xFF2A1A00),
  'task':     Color(0xFF0A1A10),
  'other':    Color(0xFF1A1F2A),
};
const _categoryIcons = {
  'travel':   Icons.flight_rounded,
  'movie':    Icons.movie_outlined,
  'occasion': Icons.celebration_outlined,
  'birthday': Icons.cake_outlined,
  'task':     Icons.task_alt_rounded,
  'other':    Icons.more_horiz_rounded,
};
const _moods = ['😀', '🥰', '😌', '😔', '😴', '🤔'];

// ── Screen ─────────────────────────────────────────────────────────────────────
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view = ref.watch(calendarViewProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Calendar',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
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
    final isDark   = Theme.of(context).brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
      child: Column(children: [
        Row(children: [
          TextButton.icon(
            onPressed: () => _pickMonth(context, ref, focused),
            icon: const Icon(Icons.expand_more_rounded, color: _mc),
            label: Text(_monthTitle(focused),
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 18)),
          ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: _mc, side: const BorderSide(color: _mc)),
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDayProvider.notifier).state = now;
              ref.read(focusedMonthProvider.notifier).state =
                  DateTime(now.year, now.month);
              ref.read(calendarViewProvider.notifier).state = 'day';
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
                entry: entries[dateKey(day)],
                isDark: isDark),
            todayBuilder: (ctx, day, _) => _DayCell(
                day: day,
                isToday: true,
                events: eventMap[dateKey(day)] ?? const [],
                entry: entries[dateKey(day)],
                isDark: isDark),
            selectedBuilder: (ctx, day, _) => _DayCell(
                day: day,
                isSelected: true,
                events: eventMap[dateKey(day)] ?? const [],
                entry: entries[dateKey(day)],
                isDark: isDark),
            markerBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ]),
    );
  }

  Future<void> _pickMonth(BuildContext context, WidgetRef ref, DateTime focused) async {
    final year = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Select year'),
        content: SizedBox(
          width: 320, height: 320,
          child: YearPicker(
            firstDate: DateTime(2020), lastDate: DateTime(2035),
            selectedDate: focused,
            onChanged: (d) => Navigator.of(dialogCtx).pop(d.year))),
      ),
    );
    if (year == null || !context.mounted) return;
    final month = await showDialog<int>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Select month'),
        content: Wrap(
          spacing: 8, runSpacing: 8,
          children: List.generate(12, (i) => ChoiceChip(
            label: Text(_months[i + 1]),
            selected: focused.month == i + 1,
            onSelected: (_) => Navigator.of(dialogCtx).pop(i + 1)))),
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
  final bool isToday, isSelected, isDark;
  final List<CalendarEvent> events;
  final DayEntry? entry;
  const _DayCell({required this.day, this.isToday=false, this.isSelected=false,
      required this.events, this.entry, this.isDark=false});

  @override
  Widget build(BuildContext context) {
    final dots = events.take(3).toList();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.all(3),
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? _mc.withValues(alpha: .14)
            : isToday ? _mc.withValues(alpha: .07)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected ? Border.all(color: _mc) : null),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('${day.day}', style: GoogleFonts.inter(
            fontWeight: FontWeight.w700, fontSize: 13,
            color: isSelected || isToday ? _mc : null)),
        const SizedBox(height: 2),
        if (entry?.mood != null)
          Text(entry!.mood!, style: const TextStyle(fontSize: 14))
        else
          const SizedBox(height: 14),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: dots.map((e) => Container(
              width: 5, height: 5,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                  color: _dotColor(e), shape: BoxShape.circle))).toList()),
      ]),
    );
  }
  Color _dotColor(CalendarEvent e) => e.itemType == 'task' ? Colors.green
      : e.itemType == 'birthday' ? Colors.orange : _mc;
}

// ── Selected day panel ─────────────────────────────────────────────────────────
class _SelectedDayPanel extends ConsumerWidget {
  const _SelectedDayPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day     = dayOnly(ref.watch(selectedDayProvider));
    final today   = dayOnly(DateTime.now());
    final isToday  = day == today;
    final isPast   = day.isBefore(today);
    final entry   = ref.watch(dayEntryProvider).valueOrNull;
    final events  = ref.watch(dayEventsProvider).valueOrNull ?? [];

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(_fullDate(day),
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800))),
          if (!isPast)
            GestureDetector(
              onTap: () => _showAddMenu(context, ref, day, isToday: isToday),
              child: Container(
                width: 34, height: 34,
                decoration: const BoxDecoration(color: _mc, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, size: 20, color: Colors.white)),
            ),
        ]),
        if (isPast && entry != null) ...[
          const SizedBox(height: 12),
          _DiaryPreview(entry: entry),
        ],
        if (events.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...events.map((e) => _EventTile(event: e, readOnly: isPast)),
        ] else ...[
          const SizedBox(height: 10),
          Text('Nothing scheduled.',
              style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
        ],
      ]),
    );
  }

  void _showAddMenu(BuildContext context, WidgetRef ref, DateTime day,
      {required bool isToday}) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _AddMenuSheet(day: day, isToday: isToday, ref: ref),
    );
  }
}

// ── Add menu sheet ─────────────────────────────────────────────────────────────
class _AddMenuSheet extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final WidgetRef ref;
  const _AddMenuSheet({required this.day, required this.isToday, required this.ref});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Center(child: Container(width:40, height:4, margin: const EdgeInsets.only(bottom:16),
              decoration: BoxDecoration(color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2)))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Add New', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w800))),
          const SizedBox(height: 8),
          if (isToday) _MenuTile(icon: Icons.book_outlined, color: const Color(0xFF8B5CF6),
              label: 'Diary Note', subtitle: 'Write about today',
              onTap: () { Navigator.pop(context); _showDiarySheet(context, ref); }),
          _MenuTile(icon: Icons.task_alt_rounded, color: Colors.green.shade600,
              label: 'Task', subtitle: 'Add a to-do',
              onTap: () { Navigator.pop(context); _showTaskDialog(context, ref, day); }),
          _MenuTile(icon: Icons.event_outlined, color: _mc,
              label: 'Event', subtitle: 'Travel, movie, occasion, other',
              onTap: () { Navigator.pop(context); _showEventSheet(context, ref, day); }),
          _MenuTile(icon: Icons.cake_outlined, color: Colors.orange.shade600,
              label: 'Birthday', subtitle: 'Recurring yearly reminder',
              onTap: () { Navigator.pop(context); _showBirthdaySheet(context, ref, day); }),
        ]),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon; final Color color; final String label, subtitle;
  final VoidCallback onTap;
  const _MenuTile({required this.icon, required this.color, required this.label,
      required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12), child: Row(children: [
      Container(width:46, height:46,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color, size: 22)),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ])),
      Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant, size: 20),
    ])),
  );
}

// ── Event tile (tappable → preview) ───────────────────────────────────────────
class _EventTile extends ConsumerWidget {
  final CalendarEvent event;
  final bool readOnly;
  const _EventTile({required this.event, this.readOnly = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final type   = event.itemType ?? event.category;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color  = isDark
        ? (_categoryDarkColors[type] ?? const Color(0xFF1A1F2A))
        : (_categoryColors[type] ?? const Color(0xFFF1F5F9));
    final icon   = _categoryIcons[type] ?? Icons.event_outlined;

    return GestureDetector(
      onTap: () => _showPreview(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          if (type == 'task')
            Checkbox(
              value: event.isDone, activeColor: _mc,
              onChanged: readOnly ? null : (_) async {
                final a = await ref.read(calendarActionsProvider.future);
                await a.toggleEventDone(event);
              },
              visualDensity: VisualDensity.compact)
          else
            Padding(padding: const EdgeInsets.only(right: 10),
                child: Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14,
                decoration: event.isDone ? TextDecoration.lineThrough : null)),
            if (event.description?.isNotEmpty == true)
              Text(event.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            Text(_categoryLabels[type] ?? type,
                style: GoogleFonts.inter(fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ])),
          Icon(Icons.chevron_right_rounded, size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
        ]),
      ),
    );
  }

  void _showPreview(BuildContext context, WidgetRef ref) {
    final day   = dayOnly(DateTime.parse(event.date.length == 10 ? '${event.date}T00:00:00' : event.date));
    final today = dayOnly(DateTime.now());
    final isPast = day.isBefore(today);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _EventPreviewSheet(event: event, isPast: isPast, ref: ref),
    );
  }
}

// ── Event preview + edit/delete sheet ─────────────────────────────────────────
class _EventPreviewSheet extends StatelessWidget {
  final CalendarEvent event;
  final bool isPast;
  final WidgetRef ref;
  const _EventPreviewSheet({required this.event, required this.isPast, required this.ref});

  @override
  Widget build(BuildContext context) {
    final type  = event.itemType ?? event.category;
    final icon  = _categoryIcons[type] ?? Icons.event_outlined;
    final color = _categoryColors[type] ?? const Color(0xFFF1F5F9);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      builder: (ctx, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20,20,20,32), children: [
        // Header
        Row(children: [
          Container(width:44, height:44,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: _mc)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(event.title, style: GoogleFonts.inter(fontSize: 19, fontWeight: FontWeight.w800)),
            Text(_categoryLabels[type] ?? type,
                style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 20),
        // Details
        _PreviewRow(icon: Icons.calendar_today_outlined, label: 'Date', value: _fmtDate(event.date)),
        if (event.startTime != null)
          _PreviewRow(icon: Icons.schedule_outlined, label: 'Start', value: _fmtTime(event.startTime!)),
        if (event.endTime != null)
          _PreviewRow(icon: Icons.schedule_outlined, label: 'End / Arrival', value: _fmtTime(event.endTime!)),
        if (event.description?.isNotEmpty == true)
          _PreviewRow(icon: Icons.notes_rounded, label: 'Notes', value: event.description!),
        if (event.isRecurring)
          _PreviewRow(icon: Icons.repeat_rounded, label: 'Recurrence', value: 'Every year'),
        if (event.attachmentPath != null)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: Row(children: [
            const Icon(Icons.attach_file_rounded, size: 16, color: _mc),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: () => _openAttachment(context, event.attachmentPath!),
              child: Text(event.attachmentPath!.split('/').last,
                  style: GoogleFonts.inter(color: _mc, decoration: TextDecoration.underline)),
            )),
          ])),
        _PreviewRow(icon: Icons.access_time_outlined, label: 'Created',
            value: _fmtTs(event.createdAt)),
        const SizedBox(height: 24),
        // Actions
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (!isPast)
            OutlinedButton.icon(
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(foregroundColor: _mc, side: const BorderSide(color: _mc)),
              onPressed: () {
                Navigator.of(context).pop();
                _openEdit(context);
              }),
          if (!isPast) const SizedBox(width: 16),
          TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, size: 16),
            label: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => _confirmDelete(context)),
        ]),
      ]),
    );
  }

  void _openEdit(BuildContext context) {
    final type = event.itemType ?? event.category;
    if (type == 'task') {
      showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
          builder: (_) => _TaskEditSheet(event: event, ref: ref));
    } else if (type == 'birthday') {
      showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
          builder: (_) => _BirthdayEditSheet(event: event, ref: ref));
    } else {
      showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
          builder: (_) => _EventEditSheet(event: event, ref: ref));
    }
  }

  void _confirmDelete(BuildContext context) {
    final isRecurring = event.isRecurring;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(isRecurring ? 'Delete Birthday Reminder?' : 'Delete this event?'),
        content: Text(isRecurring
            ? 'This will permanently remove "${event.title}" from all future years.'
            : 'Remove "${event.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogCtx).pop();
              Navigator.of(context).pop();
              final a = await ref.read(calendarActionsProvider.future);
              await a.deleteEvent(event);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete')),
        ]),
    );
  }

  void _openAttachment(BuildContext context, String path) {
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File not available or moved'), backgroundColor: Colors.orange));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _FileViewerPage(path: path)));
  }

  static String _fmtDate(String date) {
    try {
      final d = DateTime.parse('${date}T00:00:00');
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
    } catch (_) { return date; }
  }
  static String _fmtTime(String iso) {
    try {
      final d = DateTime.parse(iso);
      return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year} '
             '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';
    } catch (_) { return iso; }
  }
  static String _fmtTs(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms);
    return '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
  }
}

class _PreviewRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const _PreviewRow({required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
      const SizedBox(width: 8),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: GoogleFonts.inter(fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
        Text(value, style: GoogleFonts.inter(fontSize: 14)),
      ])),
    ]),
  );
}

// ── Task edit sheet ────────────────────────────────────────────────────────────
class _TaskEditSheet extends ConsumerStatefulWidget {
  final CalendarEvent event; final WidgetRef ref;
  const _TaskEditSheet({required this.event, required this.ref});
  @override ConsumerState<_TaskEditSheet> createState() => _TaskEditSheetState();
}
class _TaskEditSheetState extends ConsumerState<_TaskEditSheet> {
  late TextEditingController _title, _desc;
  bool _saving = false;
  @override void initState() {
    super.initState();
    _title = TextEditingController(text: widget.event.title);
    _desc  = TextEditingController(text: widget.event.description ?? '');
  }
  @override void dispose() { _title.dispose(); _desc.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Edit Task', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Task title')),
      const SizedBox(height: 12),
      TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description (optional)'), maxLines: 3),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _mc),
        onPressed: _saving ? null : () async {
          if (_title.text.trim().isEmpty) return;
          setState(() => _saving = true);
          try {
            final a = await ref.read(calendarActionsProvider.future);
            await a.updateEvent(widget.event.copyWith(
              title: _title.text.trim(),
              description: _desc.text.trim().isEmpty ? null : _desc.text.trim()));
            if (mounted) Navigator.pop(context);
          } catch (e) {
            setState(() => _saving = false);
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
          }
        },
        child: Text(_saving ? 'Saving…' : 'Save Changes')),
    ])));
}

// ── Birthday edit sheet ────────────────────────────────────────────────────────
class _BirthdayEditSheet extends ConsumerStatefulWidget {
  final CalendarEvent event; final WidgetRef ref;
  const _BirthdayEditSheet({required this.event, required this.ref});
  @override ConsumerState<_BirthdayEditSheet> createState() => _BirthdayEditSheetState();
}
class _BirthdayEditSheetState extends ConsumerState<_BirthdayEditSheet> {
  late TextEditingController _person, _notes;
  bool _saving = false;
  @override void initState() {
    super.initState();
    _person = TextEditingController(text: widget.event.title);
    _notes  = TextEditingController(text: widget.event.description ?? '');
  }
  @override void dispose() { _person.dispose(); _notes.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Edit Birthday', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text('Changes apply to all future years', style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 16),
      TextField(controller: _person, decoration: const InputDecoration(labelText: 'Person name')),
      const SizedBox(height: 12),
      TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes (optional)'), maxLines: 2),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade600),
        onPressed: _saving ? null : () async {
          if (_person.text.trim().isEmpty) return;
          setState(() => _saving = true);
          try {
            final a = await ref.read(calendarActionsProvider.future);
            await a.updateEvent(widget.event.copyWith(
              title: _person.text.trim(),
              description: _notes.text.trim().isEmpty ? null : _notes.text.trim()));
            if (mounted) Navigator.pop(context);
          } catch (e) {
            setState(() => _saving = false);
          }
        },
        child: Text(_saving ? 'Saving…' : 'Save Changes')),
    ])));
}

// ── Generic event edit sheet ───────────────────────────────────────────────────
class _EventEditSheet extends ConsumerStatefulWidget {
  final CalendarEvent event; final WidgetRef ref;
  const _EventEditSheet({required this.event, required this.ref});
  @override ConsumerState<_EventEditSheet> createState() => _EventEditSheetState();
}
class _EventEditSheetState extends ConsumerState<_EventEditSheet> {
  late TextEditingController _title, _notes;
  bool _saving = false;
  @override void initState() {
    super.initState();
    _title = TextEditingController(text: widget.event.title);
    _notes = TextEditingController(text: widget.event.description ?? '');
  }
  @override void dispose() { _title.dispose(); _notes.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Edit Event', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 16),
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
      const SizedBox(height: 12),
      TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes / Description'), maxLines: 3),
      const SizedBox(height: 20),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _mc),
        onPressed: _saving ? null : () async {
          if (_title.text.trim().isEmpty) return;
          setState(() => _saving = true);
          try {
            final a = await ref.read(calendarActionsProvider.future);
            await a.updateEvent(widget.event.copyWith(
              title: _title.text.trim(),
              description: _notes.text.trim().isEmpty ? null : _notes.text.trim()));
            if (mounted) Navigator.pop(context);
          } catch (e) {
            setState(() => _saving = false);
          }
        },
        child: Text(_saving ? 'Saving…' : 'Save Changes')),
    ])));
}

// ── Filter bar ─────────────────────────────────────────────────────────────────
class _FilterBar extends ConsumerWidget {
  final String view;
  const _FilterBar({required this.view});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const filters = [('Today','day'),('This Week','week'),('This Month','month')];
    return Row(children: filters.map((f) {
      final sel = view == f.$2;
      return Padding(padding: const EdgeInsets.only(right: 8), child: ChoiceChip(
        label: Text(f.$1),
        selected: sel,
        selectedColor: (Theme.of(context).brightness == Brightness.dark ? _mc.withValues(alpha: 0.16) : _mcl),
        checkmarkColor: _mc,
        side: BorderSide(color: sel ? _mc : Theme.of(context).dividerColor),
        labelStyle: GoogleFonts.inter(
          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
          color: sel ? _mc : Theme.of(context).colorScheme.onSurfaceVariant),
        onSelected: (_) {
          ref.read(calendarViewProvider.notifier).state = f.$2;
          if (f.$2 == 'day') {
            final now = DateTime.now();
            ref.read(selectedDayProvider.notifier).state = now;
            ref.read(focusedMonthProvider.notifier).state = DateTime(now.year, now.month);
          }
        }));
    }).toList());
  }
}

// ── Activity section ───────────────────────────────────────────────────────────
class _ActivitySection extends ConsumerWidget {
  const _ActivitySection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final view   = ref.watch(calendarViewProvider);
    final events = view == 'month'
        ? ref.watch(monthEventListProvider).valueOrNull ?? []
        : view == 'week'
            ? ref.watch(weekEventsProvider).valueOrNull ?? []
            : ref.watch(dayEventsProvider).valueOrNull ?? [];

    if (events.isEmpty) return const SizedBox.shrink();

    // For week/month: group by date and show date headers
    final showDates = view != 'day';

    if (showDates) {
      final grouped = <String, List<CalendarEvent>>{};
      for (final e in events) { grouped.putIfAbsent(e.date, () => []).add(e); }
      final sortedDates = grouped.keys.toList()..sort();

      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final date in sortedDates) ...[
            _DateGroupHeader(date: date),
            const SizedBox(height: 8),
            ...grouped[date]!.map((e) => _EventTile(event: e, readOnly: false)),
            const SizedBox(height: 8),
          ],
        ]),
      );
    }

    // Day view — no date headers needed
    final tasks     = events.where((e) => e.itemType == 'task').toList();
    final evts      = events.where((e) => e.itemType == 'event').toList();
    final birthdays = events.where((e) => e.itemType == 'birthday').toList();

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (tasks.isNotEmpty) ...[
          _SectionHeader(icon: Icons.task_alt_rounded, color: Colors.green.shade600, label: 'Tasks'),
          const SizedBox(height: 8),
          ...tasks.map((e) => _EventTile(event: e)),
          if (evts.isNotEmpty || birthdays.isNotEmpty) const SizedBox(height: 14),
        ],
        if (evts.isNotEmpty) ...[
          _SectionHeader(icon: Icons.event_outlined, color: _mc, label: 'Events'),
          const SizedBox(height: 8),
          ...evts.map((e) => _EventTile(event: e)),
          if (birthdays.isNotEmpty) const SizedBox(height: 14),
        ],
        if (birthdays.isNotEmpty) ...[
          _SectionHeader(icon: Icons.cake_outlined, color: Colors.orange.shade600, label: 'Birthdays'),
          const SizedBox(height: 8),
          ...birthdays.map((e) => _EventTile(event: e)),
        ],
      ]),
    );
  }
}

class _DateGroupHeader extends StatelessWidget {
  final String date;
  const _DateGroupHeader({required this.date});
  @override
  Widget build(BuildContext context) {
    String display;
    try {
      final d = DateTime.parse('${date}T00:00:00');
      display = '${_months[d.month]} ${d.day}, ${d.year}';
    } catch (_) { display = date; }
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(children: [
        const Icon(Icons.calendar_today_outlined, size: 12, color: _mc),
        const SizedBox(width: 6),
        Text(display, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: _mc)),
        const SizedBox(width: 8),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon; final Color color; final String label;
  const _SectionHeader({required this.icon, required this.color, required this.label});
  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: color), const SizedBox(width: 6),
    Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
  ]);
}

// ── Diary sheets ───────────────────────────────────────────────────────────────
void _showDiarySheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _DiarySheet(outerRef: ref));
}

class _DiarySheet extends ConsumerStatefulWidget {
  final WidgetRef outerRef;
  const _DiarySheet({required this.outerRef});
  @override ConsumerState<_DiarySheet> createState() => _DiarySheetState();
}
class _DiarySheetState extends ConsumerState<_DiarySheet> {
  late String _mood; late TextEditingController _diary; bool _saving = false;
  @override void initState() {
    super.initState();
    final existing = widget.outerRef.read(dayEntryProvider).valueOrNull;
    _mood  = existing?.mood ?? _moods.first;
    _diary = TextEditingController(text: existing?.diary ?? '');
  }
  @override void dispose() { _diary.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(24,24,24,MediaQuery.viewInsetsOf(context).bottom+24),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Diary Note', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
      const SizedBox(height: 4),
      Text(_fullDate(dayOnly(DateTime.now())), style: GoogleFonts.inter(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 20),
      Text('How are you feeling?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _moods.map((m) => GestureDetector(
        onTap: () => setState(() => _mood = m),
        child: AnimatedContainer(duration: const Duration(milliseconds: 150),
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: _mood == m ? _mc.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _mood == m ? _mc : Theme.of(context).dividerColor, width: _mood == m ? 2 : 1)),
          child: Center(child: Text(m, style: const TextStyle(fontSize: 24)))))).toList()),
      const SizedBox(height: 16),
      TextField(controller: _diary, maxLines: 5, decoration: const InputDecoration(labelText: 'Write about your day...', alignLabelWithHint: true)),
      const SizedBox(height: 20),
      Row(children: [
        Expanded(child: OutlinedButton(
          style: OutlinedButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant, side: BorderSide(color: Theme.of(context).dividerColor)),
          onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel'))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: FilledButton(
          style: FilledButton.styleFrom(backgroundColor: _mc),
          onPressed: _saving ? null : () async {
            setState(() => _saving = true);
            try {
              final day = ref.read(selectedDayProvider);
              final existing = ref.read(dayEntryProvider).valueOrNull;
              final a = await ref.read(calendarActionsProvider.future);
              await a.saveDayEntry(DayEntry(
                id: existing?.id ?? const Uuid().v4(), date: dateKey(day),
                mood: _mood, diary: _diary.text.trim().isEmpty ? null : _diary.text.trim()));
              if (mounted) Navigator.of(context).pop();
            } catch (_) { setState(() => _saving = false); }
          },
          child: Text(_saving ? 'Saving…' : 'Save'))),
      ]),
    ])));
}

class _DiaryPreview extends StatelessWidget {
  final DayEntry entry;
  const _DiaryPreview({required this.entry});
  @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [const Icon(Icons.book_outlined, size:14), const SizedBox(width:4),
      Text('Diary', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13))]),
    const SizedBox(height: 6),
    Container(width: double.infinity, padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Text('${entry.mood ?? ''} ${(entry.diary ?? 'No diary note').trim()}', style: GoogleFonts.inter(fontSize: 14))),
    const SizedBox(height: 4),
    Text('Read-only — past date', style: GoogleFonts.inter(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
    const Divider(height: 20),
  ]);
}

// ── Add task dialog ────────────────────────────────────────────────────────────
void _showTaskDialog(BuildContext context, WidgetRef ref, DateTime day) {
  final t = TextEditingController(), d = TextEditingController();
  showDialog(context: context, builder: (ctx) => AlertDialog(
    title: const Text('Add Task'),
    content: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: t, decoration: const InputDecoration(labelText: 'Task title'), autofocus: true),
      const SizedBox(height: 10),
      TextField(controller: d, decoration: const InputDecoration(labelText: 'Description (optional)')),
    ]),
    actions: [
      TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
      FilledButton(style: FilledButton.styleFrom(backgroundColor: _mc),
        onPressed: () async {
          if (t.text.trim().isEmpty) return;
          final a = await ref.read(calendarActionsProvider.future);
          await a.addEvent(CalendarEvent(id: const Uuid().v4(), title: t.text.trim(),
            description: d.text.trim().isEmpty ? null : d.text.trim(),
            date: dateKey(day), category: 'task', itemType: 'task',
            isDone: false, createdAt: DateTime.now().millisecondsSinceEpoch));
          if (ctx.mounted) Navigator.pop(ctx);
        }, child: const Text('Add Task')),
    ]));
}

// ── Add event sheet ────────────────────────────────────────────────────────────
void _showEventSheet(BuildContext context, WidgetRef ref, DateTime day) {
  showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _EventForm(day: day));
}

class _EventForm extends ConsumerStatefulWidget {
  final DateTime day;
  const _EventForm({required this.day});
  @override ConsumerState<_EventForm> createState() => _EventFormState();
}
class _EventFormState extends ConsumerState<_EventForm> {
  final _title=TextEditingController(), _notes=TextEditingController(),
        _movie=TextEditingController(), _seats=TextEditingController(),
        _screen=TextEditingController(), _days=TextEditingController();
  String _cat = 'travel';
  DateTime? _depart, _arrive, _start;
  String? _ticket;

  @override void dispose() {
    _title.dispose(); _notes.dispose(); _movie.dispose();
    _seats.dispose(); _screen.dispose(); _days.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    const g = XTypeGroup(label: 'Files', extensions: ['pdf','jpg','jpeg','png','doc','docx']);
    final f = await openFile(acceptedTypeGroups: [g]);
    if (f != null) setState(() => _ticket = f.path);
  }

  Future<void> _pickDT(void Function(DateTime) set) async {
    final d = await showDatePicker(context: context, initialDate: widget.day, firstDate: DateTime(2020), lastDate: DateTime(2035));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    set(DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0));
    setState(() {});
  }

  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Add Event', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      TextField(controller: _title, decoration: const InputDecoration(labelText: 'Event Title')),
      const SizedBox(height: 12),
      DropdownButtonFormField(
        value: _cat,
        items: ['travel','movie','occasion','other'].map((c) =>
            DropdownMenuItem(value: c, child: Text(_categoryLabels[c]!))).toList(),
        onChanged: (v) => setState(() => _cat = v ?? _cat),
        decoration: const InputDecoration(labelText: 'Category')),
      const SizedBox(height: 12),
      if (_cat=='travel') ...[
        OutlinedButton(onPressed: ()=>_pickDT((d)=>_depart=d),
            child: Text(_depart==null?'Departure Date & Time':_fullDateTime(_depart!))),
        const SizedBox(height:8),
        OutlinedButton(onPressed: ()=>_pickDT((d)=>_arrive=d),
            child: Text(_arrive==null?'Arrival Date & Time':_fullDateTime(_arrive!))),
        const SizedBox(height:8),
        TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes')),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed: _pickAttachment,
            icon: const Icon(Icons.attach_file),
            label: Text(_ticket?.split('/').last ?? 'Attach Ticket (optional)')),
      ],
      if (_cat=='movie') ...[
        TextField(controller: _movie, decoration: const InputDecoration(labelText: 'Movie Name')),
        const SizedBox(height:8),
        OutlinedButton(onPressed: ()=>_pickDT((d)=>_start=d),
            child: Text(_start==null?'Start Time':_fullDateTime(_start!))),
        const SizedBox(height:8),
        TextField(controller: _seats, decoration: const InputDecoration(labelText: 'Seat Numbers')),
        const SizedBox(height:8),
        TextField(controller: _screen, decoration: const InputDecoration(labelText: 'Screen Number (optional)')),
      ],
      if (_cat=='occasion') ...[
        TextField(controller: _days, decoration: const InputDecoration(labelText: 'Number of Days'), keyboardType: TextInputType.number),
        const SizedBox(height:8),
        TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Address / Notes (optional)')),
      ],
      if (_cat=='other') ...[
        TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
        const SizedBox(height:8),
        OutlinedButton.icon(onPressed: _pickAttachment,
            icon: const Icon(Icons.attach_file),
            label: Text(_ticket?.split('/').last ?? 'Attachment (optional)')),
      ],
      const SizedBox(height: 18),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: _mc),
        onPressed: () async {
          if (_title.text.trim().isEmpty) return;
          final details = [
            if (_cat=='travel') _notes.text.trim(),
            if (_cat=='movie') '${_movie.text.trim()} ${_seats.text.trim()} ${_screen.text.trim()}'.trim(),
            if (_cat=='occasion') '${_days.text.trim()} days ${_notes.text.trim()}'.trim(),
            if (_cat=='other') _notes.text.trim(),
          ].where((e) => e.isNotEmpty).join('\n');
          final a = await ref.read(calendarActionsProvider.future);
          await a.addEvent(CalendarEvent(
            id: const Uuid().v4(), title: _title.text.trim(),
            description: details.isEmpty ? null : details,
            date: dateKey(widget.day), startTime: (_depart??_start)?.toIso8601String(),
            endTime: _arrive?.toIso8601String(), category: _cat, itemType: 'event',
            attachmentPath: _ticket, createdAt: DateTime.now().millisecondsSinceEpoch));
          if (mounted) Navigator.pop(context);
        },
        child: const Text('Add Event')),
    ])));
}

// ── Birthday sheet (recurring) ─────────────────────────────────────────────────
void _showBirthdaySheet(BuildContext context, WidgetRef ref, DateTime day) {
  showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true,
      builder: (_) => _BirthdayForm(day: day));
}

class _BirthdayForm extends ConsumerStatefulWidget {
  final DateTime day;
  const _BirthdayForm({required this.day});
  @override ConsumerState<_BirthdayForm> createState() => _BirthdayFormState();
}
class _BirthdayFormState extends ConsumerState<_BirthdayForm> {
  final _person=TextEditingController(), _gift=TextEditingController(),
        _price=TextEditingController(), _cat=TextEditingController(text:'Gift'),
        _url=TextEditingController();
  bool _idea=false; String? _image; DateTime? _target;
  @override void dispose() {
    _person.dispose(); _gift.dispose(); _price.dispose(); _cat.dispose(); _url.dispose();
    super.dispose();
  }
  Future<void> _pickImage() async {
    const g = XTypeGroup(label:'Images', extensions:['jpg','jpeg','png','webp']);
    final f = await openFile(acceptedTypeGroups:[g]);
    if (f!=null) setState(()=>_image=f.path);
  }
  @override Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20,20,20,MediaQuery.viewInsetsOf(context).bottom+20),
    child: SingleChildScrollView(child: Column(mainAxisSize:MainAxisSize.min, crossAxisAlignment:CrossAxisAlignment.stretch, children:[
      Text('Add Birthday', style: GoogleFonts.inter(fontSize:18, fontWeight:FontWeight.w800)),
      const SizedBox(height: 4),
      Row(children: [const Icon(Icons.repeat_rounded, size:14, color:_mc), const SizedBox(width:4),
        Text('Repeats every year', style: GoogleFonts.inter(fontSize:12, color:_mc))]),
      const SizedBox(height: 12),
      TextField(controller: _person, decoration: const InputDecoration(labelText:'Person Name')),
      const SizedBox(height: 8),
      SwitchListTile(value:_idea, onChanged:(v)=>setState(()=>_idea=v), activeColor:_mc,
          contentPadding:EdgeInsets.zero,
          title: Text('Add Gift Idea', style: GoogleFonts.inter(fontWeight:FontWeight.w500))),
      if (_idea) ...[
        OutlinedButton.icon(onPressed:_pickImage, icon:const Icon(Icons.image_outlined),
            label:Text(_image?.split('/').last ?? 'Add Gift Image')),
        const SizedBox(height:8),
        TextField(controller:_gift, decoration:const InputDecoration(labelText:'Gift Name')),
        const SizedBox(height:8),
        TextField(controller:_price, decoration:const InputDecoration(labelText:'Price'), keyboardType:TextInputType.number),
        const SizedBox(height:8),
        TextField(controller:_cat, decoration:const InputDecoration(labelText:'Category')),
        const SizedBox(height:8),
        OutlinedButton(
          onPressed: () async {
            final d = await showDatePicker(context:context, initialDate:widget.day, firstDate:DateTime(2020), lastDate:DateTime(2035));
            if (d!=null) setState(()=>_target=d);
          },
          child: Text(_target==null?'Target Purchase Date':_fullDate(_target!))),
        const SizedBox(height:8),
        TextField(controller:_url, decoration:const InputDecoration(labelText:'Product URL')),
      ],
      const SizedBox(height: 16),
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade600),
        onPressed: () async {
          if (_person.text.trim().isEmpty) return;
          final personName = _person.text.trim();
          final a = await ref.read(calendarActionsProvider.future);
          // Store with birthDay/birthMonth + isRecurring=true
          await a.addEvent(CalendarEvent(
            id: const Uuid().v4(), title: personName,
            date: dateKey(widget.day), category: 'birthday', itemType: 'birthday',
            createdAt: DateTime.now().millisecondsSinceEpoch,
            birthDay: widget.day.day, birthMonth: widget.day.month, isRecurring: true));
          if (_idea && _gift.text.trim().isNotEmpty) {
            final w = await ref.read(wishlistActionsProvider.future);
            await w.addItem(WishlistItem(
              id: const Uuid().v4(), name: _gift.text.trim(),
              price: double.tryParse(_price.text.trim()), imageUrl: _image,
              category: _cat.text.trim().isEmpty ? 'Gift' : 'Gift • ${_cat.text.trim()}',
              productUrl: _url.text.trim().isEmpty ? null : _url.text.trim(),
              targetPurchaseAt: _target?.millisecondsSinceEpoch,
              isPurchased: false, createdAt: DateTime.now().millisecondsSinceEpoch,
              giftFor: personName, giftDate: widget.day.millisecondsSinceEpoch));
          }
          if (mounted) Navigator.pop(context);
        },
        child: const Text('Save Birthday')),
    ])));
}

// ── File viewer ────────────────────────────────────────────────────────────────
class _FileViewerPage extends StatelessWidget {
  final String path;
  const _FileViewerPage({required this.path});
  @override Widget build(BuildContext context) {
    final lower = path.toLowerCase();
    final isImg = lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
    return Scaffold(
      appBar: AppBar(title: Text(path.split('/').last, maxLines:1, overflow:TextOverflow.ellipsis)),
      body: isImg ? InteractiveViewer(child: Center(child: Image.file(File(path), fit:BoxFit.contain)))
          : const Center(child: Text('Preview not available')));
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────
const _months = ['','January','February','March','April','May','June',
    'July','August','September','October','November','December'];
String _monthTitle(DateTime d) => '${_months[d.month]} ${d.year}';
String _fullDate(DateTime d) => '${_months[d.month]} ${d.day}, ${d.year}';
String _fullDateTime(DateTime d) =>
    '${_fullDate(d)} ${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}';