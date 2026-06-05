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

// ── Module color shortcuts ────────────────────────────────────────────────────
const _mc  = AndroidTheme.calendarPrimary;
const _mcl = AndroidTheme.calendarPrimaryLight;

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
const _categoryIcons = {
  'travel':   Icons.flight_rounded,
  'movie':    Icons.movie_outlined,
  'occasion': Icons.celebration_outlined,
  'birthday': Icons.cake_outlined,
  'task':     Icons.task_alt_rounded,
  'diary':    Icons.book_outlined,
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

// ── Calendar widget card ───────────────────────────────────────────────────────
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
            icon: const Icon(Icons.expand_more_rounded, color: _mc),
            label: Text(_monthTitle(focused),
                style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: AndroidTheme.textPrimary)),
          ),
          const Spacer(),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
                foregroundColor: _mc,
                side: const BorderSide(color: _mc)),
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
            ? _mc.withValues(alpha: .14)
            : isToday
                ? _mc.withValues(alpha: .07)
                : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: isSelected ? Border.all(color: _mc) : null,
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('${day.day}',
            style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: isSelected
                    ? _mc
                    : isToday
                        ? _mc
                        : AndroidTheme.textPrimary)),
        const SizedBox(height: 2),
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
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
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
          : _mc;
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
          // Date row + add button
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
                  onTap: () => _showAddMenu(
                      context, ref, day,
                      isToday: isToday),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: const BoxDecoration(
                        color: _mc, shape: BoxShape.circle),
                    child: const Icon(Icons.add_rounded,
                        size: 20, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Past diary — read-only
          if (isPast && entry != null) ...[
            _DiaryPreview(entry: entry),
            const SizedBox(height: 12),
          ],

          // Events for the day
          _DayEventList(events: events, readOnly: isPast),
        ],
      ),
    );
  }

  /// Add menu — diary is now a proper bottom sheet, consistent with Task/Event/Birthday
  void _showAddMenu(
    BuildContext context,
    WidgetRef ref,
    DateTime day, {
    required bool isToday,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (sheetCtx) => _AddMenuSheet(
        day: day,
        isToday: isToday,
        onClose: () => Navigator.pop(sheetCtx),
        ref: ref,
      ),
    );
  }
}

// ── Add menu bottom sheet ──────────────────────────────────────────────────────
class _AddMenuSheet extends StatelessWidget {
  final DateTime day;
  final bool isToday;
  final VoidCallback onClose;
  final WidgetRef ref;

  const _AddMenuSheet({
    required this.day,
    required this.isToday,
    required this.onClose,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: AndroidTheme.divider,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text('Add New',
                  style: GoogleFonts.inter(
                      fontSize: 17, fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 8),

            if (isToday)
              _MenuTile(
                icon: Icons.book_outlined,
                color: const Color(0xFF8B5CF6),
                label: 'Diary Note',
                subtitle: 'Write about today',
                onTap: () {
                  onClose();
                  _showDiarySheet(context, ref);
                },
              ),
            _MenuTile(
              icon: Icons.task_alt_rounded,
              color: Colors.green.shade600,
              label: 'Task',
              subtitle: 'Add a to-do for this day',
              onTap: () {
                onClose();
                _showTaskDialog(context, ref, day);
              },
            ),
            _MenuTile(
              icon: Icons.event_outlined,
              color: _mc,
              label: 'Event',
              subtitle: 'Travel, movie, occasion',
              onTap: () {
                onClose();
                _showEventSheet(context, ref, day);
              },
            ),
            _MenuTile(
              icon: Icons.cake_outlined,
              color: Colors.orange.shade600,
              label: 'Birthday',
              subtitle: 'Add birthday & gift idea',
              onTap: () {
                onClose();
                _showBirthdaySheet(context, ref, day);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  Text(subtitle,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AndroidTheme.textTertiary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: AndroidTheme.textTertiary, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Diary bottom sheet (same pattern as Task/Event/Birthday) ──────────────────
void _showDiarySheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (_) => _DiarySheet(ref: ref),
  );
}

class _DiarySheet extends ConsumerStatefulWidget {
  // Pass the outer ref so we can read today's existing entry
  final WidgetRef outerRef;
  const _DiarySheet({required WidgetRef ref}) : outerRef = ref;

  @override
  ConsumerState<_DiarySheet> createState() => _DiarySheetState();
}

class _DiarySheetState extends ConsumerState<_DiarySheet> {
  late String _mood;
  late TextEditingController _diary;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.outerRef.read(dayEntryProvider).valueOrNull;
    _mood  = existing?.mood ?? _moods.first;
    _diary = TextEditingController(text: existing?.diary ?? '');
  }

  @override
  void dispose() {
    _diary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final day     = ref.read(selectedDayProvider);
      final existing = ref.read(dayEntryProvider).valueOrNull;
      final actions = await ref.read(calendarActionsProvider.future);
      await actions.saveDayEntry(DayEntry(
        id:    existing?.id ?? const Uuid().v4(),
        date:  dateKey(day),
        mood:  _mood,
        diary: _diary.text.trim().isEmpty ? null : _diary.text.trim(),
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Unable to save diary: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Diary Note',
                style: GoogleFonts.inter(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(_fullDate(dayOnly(DateTime.now())),
                style: GoogleFonts.inter(
                    fontSize: 13, color: AndroidTheme.textTertiary)),
            const SizedBox(height: 20),
            Text('How are you feeling?',
                style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AndroidTheme.textSecondary)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods
                  .map((m) => GestureDetector(
                        onTap: () => setState(() => _mood = m),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _mood == m
                                ? _mc.withValues(alpha: 0.15)
                                : AndroidTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _mood == m ? _mc : AndroidTheme.divider,
                              width: _mood == m ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(m,
                                style: const TextStyle(fontSize: 24)),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _diary,
              maxLines: 5,
              decoration: const InputDecoration(
                  labelText: 'Write about your day...',
                  alignLabelWithHint: true),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                        foregroundColor: AndroidTheme.textSecondary,
                        side: const BorderSide(
                            color: AndroidTheme.divider)),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                        backgroundColor: _mc),
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Diary preview (past dates, read-only) ─────────────────────────────────────
class _DiaryPreview extends StatelessWidget {
  final DayEntry entry;
  const _DiaryPreview({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.book_outlined,
              size: 14, color: AndroidTheme.textSecondary),
          const SizedBox(width: 4),
          Text('Diary',
              style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AndroidTheme.surface,
              borderRadius: BorderRadius.circular(12)),
          child: Text(
            '${entry.mood ?? ''} ${(entry.diary ?? 'No diary note').trim()}',
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        const SizedBox(height: 4),
        Text('Read-only — past date',
            style: GoogleFonts.inter(
                fontSize: 11, color: AndroidTheme.textTertiary)),
        const Divider(height: 20),
      ],
    );
  }
}

// ── Day event list ─────────────────────────────────────────────────────────────
class _DayEventList extends ConsumerWidget {
  final List<CalendarEvent> events;
  final bool readOnly;
  const _DayEventList(
      {required this.events, this.readOnly = false});

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
    final icon  = _categoryIcons[type] ?? Icons.event_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          if (event.itemType == 'task')
            Checkbox(
              value: event.isDone,
              activeColor: _mc,
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
              padding: const EdgeInsets.only(right: 10),
              child: Icon(icon,
                  size: 18, color: AndroidTheme.textSecondary),
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
            selectedColor: _mcl,
            checkmarkColor: _mc,
            side: BorderSide(
                color: isSelected ? _mc : AndroidTheme.divider),
            labelStyle: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? _mc : AndroidTheme.textSecondary,
            ),
            onSelected: (_) {
              ref.read(calendarViewProvider.notifier).state = f.$2;
              // TODAY filter: also jump calendar + selected date to today
              if (f.$2 == 'day') {
                final now = DateTime.now();
                ref.read(selectedDayProvider.notifier).state = now;
                ref.read(focusedMonthProvider.notifier).state =
                    DateTime(now.year, now.month);
              }
            },
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
    final evts      = events.where((e) => e.itemType == 'event').toList();
    final birthdays = events.where((e) => e.itemType == 'birthday').toList();

    if (tasks.isEmpty && evts.isEmpty && birthdays.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tasks.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.task_alt_rounded,
                color: Colors.green.shade600,
                label: 'Tasks'),
            const SizedBox(height: 8),
            ...tasks.map((e) => _EventTile(event: e)),
            if (evts.isNotEmpty || birthdays.isNotEmpty)
              const SizedBox(height: 14),
          ],
          if (evts.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.event_outlined, color: _mc, label: 'Events'),
            const SizedBox(height: 8),
            ...evts.map((e) => _EventTile(event: e)),
            if (birthdays.isNotEmpty) const SizedBox(height: 14),
          ],
          if (birthdays.isNotEmpty) ...[
            _SectionHeader(
                icon: Icons.cake_outlined,
                color: Colors.orange.shade600,
                label: 'Birthdays'),
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
  final Color color;
  final String label;
  const _SectionHeader(
      {required this.icon, required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 15, color: color),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w800, fontSize: 14)),
    ]);
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
              decoration: const InputDecoration(labelText: 'Task title'),
              autofocus: true),
          const SizedBox(height: 10),
          TextField(
              controller: desc,
              decoration: const InputDecoration(
                  labelText: 'Description (optional)')),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel')),
        FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _mc),
            onPressed: () async {
              if (title.text.trim().isEmpty) return;
              try {
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
              } catch (e) {
                if (dialogCtx.mounted) {
                  ScaffoldMessenger.of(dialogCtx).showSnackBar(SnackBar(
                      content: Text('Unable to save task: $e'),
                      backgroundColor: Colors.red));
                }
              }
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
            TextField(controller: _title,
                decoration:
                    const InputDecoration(labelText: 'Event Title')),
            const SizedBox(height: 12),
            DropdownButtonFormField(
              value: _cat,
              items: const ['travel', 'movie', 'occasion']
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(_categoryLabels[c]!)))
                  .toList(),
              onChanged: (v) => setState(() => _cat = v ?? _cat),
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 12),
            if (_cat == 'travel') ...[
              OutlinedButton(
                onPressed: () => _pickDateTime((d) => _depart = d),
                child: Text(_depart == null
                    ? 'Departure Date & Time'
                    : _fullDateTime(_depart!)),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _pickDateTime((d) => _arrive = d),
                child: Text(_arrive == null
                    ? 'Arrival Date & Time'
                    : _fullDateTime(_arrive!)),
              ),
              const SizedBox(height: 8),
              TextField(controller: _notes,
                  decoration:
                      const InputDecoration(labelText: 'Details / Notes')),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickTicket,
                icon: const Icon(Icons.attach_file),
                label: Text(_ticket?.split('/').last ??
                    'Attach Ticket (optional)'),
              ),
            ],
            if (_cat == 'movie') ...[
              TextField(controller: _movie,
                  decoration:
                      const InputDecoration(labelText: 'Movie Name')),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () => _pickDateTime((d) => _start = d),
                child: Text(_start == null
                    ? 'Start Time'
                    : _fullDateTime(_start!)),
              ),
              const SizedBox(height: 8),
              TextField(controller: _seats,
                  decoration:
                      const InputDecoration(labelText: 'Seat Numbers')),
              const SizedBox(height: 8),
              TextField(controller: _screen,
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
              const SizedBox(height: 8),
              TextField(controller: _notes,
                  decoration: const InputDecoration(
                      labelText: 'Address / Notes (optional)')),
            ],
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _mc),
              onPressed: () async {
                if (_title.text.trim().isEmpty) return;
                try {
                  final details = [
                    if (_cat == 'travel') _notes.text.trim(),
                    if (_cat == 'movie')
                      '${_movie.text.trim()} ${_seats.text.trim()} ${_screen.text.trim()}'.trim(),
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
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Unable to save event: $e'),
                        backgroundColor: Colors.red));
                  }
                }
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
            TextField(controller: _person,
                decoration:
                    const InputDecoration(labelText: 'Person Name')),
            const SizedBox(height: 8),
            SwitchListTile(
              value: _idea,
              onChanged: (v) => setState(() => _idea = v),
              activeColor: _mc,
              contentPadding: EdgeInsets.zero,
              title: Text('Add Gift Idea',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            ),
            if (_idea) ...[
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined),
                label: Text(_image?.split('/').last ?? 'Add Gift Image'),
              ),
              const SizedBox(height: 8),
              TextField(controller: _gift,
                  decoration:
                      const InputDecoration(labelText: 'Gift Name')),
              const SizedBox(height: 8),
              TextField(
                controller: _price,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(controller: _cat,
                  decoration:
                      const InputDecoration(labelText: 'Category')),
              const SizedBox(height: 8),
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
              const SizedBox(height: 8),
              TextField(controller: _url,
                  decoration:
                      const InputDecoration(labelText: 'Product URL')),
            ],
            const SizedBox(height: 16),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: _mc),
              onPressed: () async {
                if (_person.text.trim().isEmpty) return;
                try {
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
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Unable to save: $e'),
                        backgroundColor: Colors.red));
                  }
                }
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
String _fullDate(DateTime d) =>
    '${_months[d.month]} ${d.day}, ${d.year}';
String _fullDateTime(DateTime d) =>
    '${_fullDate(d)} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';