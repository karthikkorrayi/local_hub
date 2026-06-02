import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/android_theme.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/day_entry.dart';
import '../../data/models/week_todo.dart';
import '../../data/models/job.dart';
import 'calendar_provider.dart';

// ── Constants ──────────────────────────────────────────────────────────────────
const _kCategories = ['travel', 'entertainment', 'meeting', 'busy', 'occasion', 'personal', 'work', 'other'];
const _kCategoryLabels = {
  'travel': '✈️ Travel',
  'entertainment': '🎬 Entertainment',
  'meeting': '🤝 Meeting',
  'busy': '⛔ Busy',
  'occasion': '🎉 Occasion',
  'personal': '🏠 Personal',
  'work': '💼 Work',
  'other': '📌 Other',
};
const _kCategoryColors = {
  'travel': Color(0xFF0EA5E9),
  'entertainment': Color(0xFF8B5CF6),
  'meeting': Color(0xFFF59E0B),
  'busy': Color(0xFFEF4444),
  'occasion': Color(0xFFEC4899),
  'personal': Color(0xFF10B981),
  'work': Color(0xFF3B82F6),
  'other': Color(0xFF6B7280),
};
const _kMoods = ['😀', '😔', '😡', '😴', '😍', '🤔'];

// ── Screen ─────────────────────────────────────────────────────────────────────
class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(calendarViewProvider);

    return Scaffold(
      backgroundColor: AndroidTheme.surface,
      appBar: AppBar(
        title: Text(
          'Calendar',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: AndroidTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AndroidTheme.divider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _ViewTab(
                  label: 'Month',
                  selected: currentView == 'month',
                  onTap: () =>
                      ref.read(calendarViewProvider.notifier).state = 'month',
                ),
                _ViewTab(
                  label: 'Day',
                  selected: currentView == 'day',
                  onTap: () =>
                      ref.read(calendarViewProvider.notifier).state = 'day',
                ),
                _ViewTab(
                  label: 'Week',
                  selected: currentView == 'week',
                  onTap: () =>
                      ref.read(calendarViewProvider.notifier).state = 'week',
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 64),
        child: FloatingActionButton(
          onPressed: () => _showAddMenu(context, ref),
          backgroundColor: AndroidTheme.primary,
          foregroundColor: Colors.white,
          elevation: 2,
          child: const Icon(Icons.add_rounded),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          if (currentView != 'day') _CalendarCard(isMonthView: currentView == 'month'),
          Expanded(
            child: _DayDetailPanel(
              onEditEvent: (e) => _showEventForm(context, ref, existing: e),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventForm(BuildContext context, WidgetRef ref,
      {String itemType = 'event', CalendarEvent? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _EventFormSheet(ref: ref, existing: existing, initialType: itemType),
    );
  }


  void _showAddMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              ['birthday', 'Birthday', Icons.cake_outlined],
              ['task', 'Task', Icons.task_alt_rounded],
              ['event', 'Event', Icons.event_outlined],
              ['diary', 'Personal Diary', Icons.mood_outlined],
            ])
              ListTile(
                leading: Icon(entry[2] as IconData),
                title: Text(entry[1] as String),
                onTap: () {
                  Navigator.of(context).pop();
                  if (entry[0] == 'diary') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (_) => _DaySheet(day: ref.read(selectedDayProvider), ref: ref),
                    );
                  } else {
                    _showEventForm(context, ref, itemType: entry[0] as String);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

// ── View tab toggle ────────────────────────────────────────────────────────────
class _ViewTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AndroidTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : AndroidTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Calendar card ──────────────────────────────────────────────────────────────
class _CalendarCard extends ConsumerWidget {
  final bool isMonthView;
  const _CalendarCard({required this.isMonthView});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final monthEvents = ref.watch(monthEventsProvider).valueOrNull ?? {};
    final monthMoods = ref.watch(monthMoodProvider).valueOrNull ?? {};

    return Container(
      color: AndroidTheme.card,
      padding: const EdgeInsets.only(bottom: 8),
      child: TableCalendar(
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: selected,
        rowHeight: 54,
        calendarFormat: isMonthView
            ? CalendarFormat.month
            : CalendarFormat.week,
        selectedDayPredicate: (day) => isSameDay(day, selected),
        onDaySelected: (selectedDay, _) {
          ref.read(selectedDayProvider.notifier).state = selectedDay;
          _showDaySheet(context, ref, selectedDay);
        },
        onPageChanged: (focusedDay) {
          ref.read(selectedDayProvider.notifier).state = focusedDay;
        },
        eventLoader: (day) {
          final key = dateKey(day);
          return monthEvents[key] ?? [];
        },
        calendarBuilders: CalendarBuilders(
          // Default day — show number + mood emoji if exists
          defaultBuilder: (context, day, focusedDay) {
            final mood = monthMoods[dateKey(day)];
            return _DayCell(
              day: day,
              mood: mood,
              textColor: AndroidTheme.textPrimary,
              bgColor: Colors.transparent,
            );
          },
          // Today
          todayBuilder: (context, day, focusedDay) {
            final mood = monthMoods[dateKey(day)];
            return _DayCell(
              day: day,
              mood: mood,
              textColor: AndroidTheme.primary,
              bgColor: AndroidTheme.primary.withValues(alpha: 0.12),
              bold: true,
            );
          },
          // Selected day
          selectedBuilder: (context, day, focusedDay) {
            final mood = monthMoods[dateKey(day)];
            return _DayCell(
              day: day,
              mood: mood,
              textColor: Colors.white,
              bgColor: AndroidTheme.primary,
              bold: true,
            );
          },
          // Outside days (prev/next month)
          outsideBuilder: (context, day, focusedDay) {
            final mood = monthMoods[dateKey(day)];
            return _DayCell(
              day: day,
              mood: mood,
              textColor: AndroidTheme.textTertiary,
              bgColor: Colors.transparent,
            );
          },
          // Event dots
          markerBuilder: (context, day, events) {
            if (events.isEmpty) return const SizedBox.shrink();
            return Positioned(
              bottom: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: events.take(3).map((_) => Container(
                  width: 4,
                  height: 4,
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: const BoxDecoration(
                    color: AndroidTheme.primary,
                    shape: BoxShape.circle,
                  ),
                )).toList(),
              ),
            );
          },
        ),
        calendarStyle: const CalendarStyle(
          outsideDaysVisible: true,
          markersMaxCount: 3,
          markerSize: 4,
          cellMargin: EdgeInsets.all(3),
          cellPadding: EdgeInsets.zero,
        ),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AndroidTheme.textPrimary,
          ),
          leftChevronIcon: const Icon(
            Icons.chevron_left_rounded,
            color: AndroidTheme.primary,
          ),
          rightChevronIcon: const Icon(
            Icons.chevron_right_rounded,
            color: AndroidTheme.primary,
          ),
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AndroidTheme.textTertiary,
          ),
          weekendStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AndroidTheme.textTertiary,
          ),
        ),
      ),
    );
  }

  void _showDaySheet(BuildContext context, WidgetRef ref, DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DaySheet(day: day, ref: ref),
    );
  }
}

// ── Reusable day cell widget ───────────────────────────────────────────────────
class _DayCell extends StatelessWidget {
  final DateTime day;
  final String? mood;
  final Color textColor;
  final Color bgColor;
  final bool bold;

  const _DayCell({
    required this.day,
    required this.mood,
    required this.textColor,
    required this.bgColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              color: textColor,
              height: 1,
            ),
          ),
          if (mood != null) ...[
            const SizedBox(height: 1),
            Text(
              mood!,
              style: const TextStyle(fontSize: 10, height: 1),
            ),
          ] else
            const SizedBox(height: 11), // keep cell height consistent
        ],
      ),
    );
  }
}

// ── Day bottom sheet ───────────────────────────────────────────────────────────
class _DaySheet extends ConsumerStatefulWidget {
  final DateTime day;
  final WidgetRef ref;
  const _DaySheet({required this.day, required this.ref});

  @override
  ConsumerState<_DaySheet> createState() => _DaySheetState();
}

class _DaySheetState extends ConsumerState<_DaySheet> {
  late TextEditingController _diary;
  String? _selectedMood;
  bool _loadedEntry = false;

  bool get _isEditable {
    final now = DateTime.now();
    final d = widget.day;
    return d.year > now.year ||
        (d.year == now.year && d.month > now.month) ||
        (d.year == now.year && d.month == now.month && d.day >= now.day);
  }

  @override
  void initState() {
    super.initState();
    _diary = TextEditingController();
  }

  @override
  void dispose() {
    _diary.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final actions = await ref.read(calendarActionsProvider.future);
    final entry = DayEntry(
      id: ref.read(dayEntryProvider).valueOrNull?.id ?? const Uuid().v4(),
      date: dateKey(widget.day),
      mood: _selectedMood,
      diary: _diary.text.trim().isEmpty ? null : _diary.text.trim(),
    );
    await actions.saveDayEntry(entry);
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

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(dayEntryProvider);
    final eventsAsync = ref.watch(dayEventsProvider);
    final todosAsync = ref.watch(weekTodosProvider);
    final isPast = !_isEditable;

    // Load entry data once
    entryAsync.whenData((entry) {
      if (!_loadedEntry && entry != null) {
        _loadedEntry = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _selectedMood = entry.mood;
              _diary.text = entry.diary ?? '';
            });
          }
        });
      }
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: AndroidTheme.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AndroidTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
                  // Date header
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(widget.day),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AndroidTheme.textPrimary,
                          ),
                        ),
                      ),
                      if (isPast)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AndroidTheme.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Past day',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AndroidTheme.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Mood section ───────────────────────────────────────
                  Text(
                    isPast ? 'Mood' : 'How are you feeling?',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AndroidTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kMoods.map((emoji) {
                      final isSelected = _selectedMood == emoji;
                      return GestureDetector(
                        onTap: isPast
                            ? null
                            : () {
                                setState(() => _selectedMood =
                                    isSelected ? null : emoji);
                                _save();
                              },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AndroidTheme.primaryLight
                                : AndroidTheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? AndroidTheme.primary
                                  : AndroidTheme.divider,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                      )
                          .animate()
                          .scale(duration: 150.ms, curve: Curves.easeOut);
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // ── Diary section ──────────────────────────────────────
                  Text(
                    'Diary',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AndroidTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppCard(
                    child: TextField(
                      controller: _diary,
                      readOnly: isPast,
                      maxLines: 4,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AndroidTheme.textPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: isPast
                            ? 'No diary entry for this day'
                            : 'Write your thoughts…',
                        hintStyle: GoogleFonts.inter(
                          color: AndroidTheme.textTertiary,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      onChanged: (_) => _save(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Week todos ─────────────────────────────────────────
                  _WeekTodoInSheet(todosAsync: todosAsync),
                  const SizedBox(height: 20),

                  // ── Events ────────────────────────────────────────────
                  _EventsInSheet(
                    eventsAsync: eventsAsync,
                    onEdit: (e) {
                      Navigator.of(context).pop();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) =>
                            _EventFormSheet(ref: ref, existing: e),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Day detail panel (shown below calendar) ────────────────────────────────────
class _DayDetailPanel extends ConsumerWidget {
  final void Function(CalendarEvent) onEditEvent;
  const _DayDetailPanel({required this.onEditEvent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDayProvider);
    final eventsAsync = ref.watch(dayEventsProvider);
    final entryAsync = ref.watch(dayEntryProvider);

    String _shortDate(DateTime d) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${days[d.weekday - 1]}, ${months[d.month]} ${d.day}';
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        // Date + mood row
        Row(
          children: [
            Text(
              _shortDate(selected),
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AndroidTheme.textPrimary,
              ),
            ),
            const Spacer(),
            entryAsync.when(
              data: (entry) => entry?.mood != null
                  ? Text(
                      entry!.mood!,
                      style: const TextStyle(fontSize: 22),
                    )
                  : const SizedBox.shrink(),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 10),

        const _WeeklyOverview(),
        const SizedBox(height: 12),

        // Events quick list
        eventsAsync.when(
          data: (events) => events.isEmpty
              ? AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.touch_app_rounded,
                        color: AndroidTheme.textTertiary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tap a date to view or add details',
                        style: GoogleFonts.inter(
                          color: AndroidTheme.textTertiary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : AppCard(
                  child: Column(
                    children: events
                        .map((e) => _EventTile(event: e, onEdit: onEditEvent))
                        .toList(),
                  ),
                ),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error: $e'),
        ),
      ],
    );
  }
}



class _WeeklyOverview extends ConsumerWidget {
  const _WeeklyOverview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(weekEventsProvider).valueOrNull ?? [];
    final birthdays = events.where((e) => e.itemType == 'birthday').toList();
    final tasks = events.where((e) => e.itemType == 'task').toList();
    final regular = events.where((e) => e.itemType == null || e.itemType == 'event').toList();
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly Overview', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          _WeekLine(label: 'Birthdays this week', items: birthdays),
          _WeekLine(label: 'Tasks this week', items: tasks),
          _WeekLine(label: 'Events this week', items: regular),
        ],
      ),
    );
  }
}

class _WeekLine extends ConsumerWidget {
  final String label;
  final List<CalendarEvent> items;
  const _WeekLine({required this.label, required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          children: [
            Text('$label:', style: GoogleFonts.inter(fontSize: 12, color: AndroidTheme.textSecondary, fontWeight: FontWeight.w700)),
            if (items.isEmpty)
              Text('None', style: GoogleFonts.inter(fontSize: 12, color: AndroidTheme.textTertiary))
            else
              ...items.take(4).map((e) => ActionChip(
                    label: Text(e.title),
                    onPressed: () {
                      ref.read(selectedDayProvider.notifier).state = DateTime.parse(e.date);
                    },
                  )),
          ],
        ),
      );
}

// ── Week todos in sheet ────────────────────────────────────────────────────────
class _WeekTodoInSheet extends ConsumerStatefulWidget {
  final AsyncValue<List<WeekTodo>> todosAsync;
  const _WeekTodoInSheet({required this.todosAsync});

  @override
  ConsumerState<_WeekTodoInSheet> createState() => _WeekTodoInSheetState();
}

class _WeekTodoInSheetState extends ConsumerState<_WeekTodoInSheet> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_ctrl.text.trim().isEmpty) return;
    final selected = ref.read(selectedDayProvider);
    final actions = await ref.read(calendarActionsProvider.future);
    await actions.addTodo(WeekTodo(
      id: const Uuid().v4(),
      weekStart: weekStartKey(selected),
      title: _ctrl.text.trim(),
      isDone: false,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    ));
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final todos = widget.todosAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "This Week's Todos",
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AndroidTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        AppCard(
          child: Column(
            children: [
              ...todos.map((todo) => _TodoTile(todo: todo)),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _ctrl,
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Add todo for this week…',
                          hintStyle: GoogleFonts.inter(
                            color: AndroidTheme.textTertiary,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _add(),
                      ),
                    ),
                    GestureDetector(
                      onTap: _add,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AndroidTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: AndroidTheme.primary,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TodoTile extends ConsumerWidget {
  final WeekTodo todo;
  const _TodoTile({required this.todo});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: GestureDetector(
        onTap: () async {
          final actions = await ref.read(calendarActionsProvider.future);
          await actions.toggleTodo(todo);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: todo.isDone ? AndroidTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: todo.isDone ? AndroidTheme.primary : AndroidTheme.divider,
              width: 1.5,
            ),
          ),
          child: todo.isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : null,
        ),
      ),
      title: Text(
        todo.title,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: todo.isDone
              ? AndroidTheme.textTertiary
              : AndroidTheme.textPrimary,
          decoration: todo.isDone ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: GestureDetector(
        onTap: () async {
          final actions = await ref.read(calendarActionsProvider.future);
          await actions.deleteTodo(todo);
        },
        child: Icon(
          Icons.close_rounded,
          size: 16,
          color: AndroidTheme.textTertiary,
        ),
      ),
    );
  }
}

// ── Events in sheet ────────────────────────────────────────────────────────────
class _EventsInSheet extends ConsumerWidget {
  final AsyncValue<List<CalendarEvent>> eventsAsync;
  final void Function(CalendarEvent) onEdit;

  const _EventsInSheet({required this.eventsAsync, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = eventsAsync.valueOrNull ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Events',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AndroidTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        events.isEmpty
            ? AppCard(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No events for this day',
                  style: GoogleFonts.inter(
                    color: AndroidTheme.textTertiary,
                    fontSize: 13,
                  ),
                ),
              )
            : AppCard(
                child: Column(
                  children: events
                      .map((e) => _EventTile(event: e, onEdit: onEdit))
                      .toList(),
                ),
              ),
      ],
    );
  }
}

// ── Event tile ─────────────────────────────────────────────────────────────────
class _EventTile extends ConsumerWidget {
  final CalendarEvent event;
  final void Function(CalendarEvent) onEdit;

  const _EventTile({required this.event, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color =
        _kCategoryColors[event.category] ?? const Color(0xFF6B7280);

    return ListTile(
      onTap: () => onEdit(event),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(
        event.title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AndroidTheme.textPrimary,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${event.itemType ?? 'event'}${event.itemType == 'task' ? (event.isDone ? ' • Complete' : ' • Pending') : event.itemType == 'birthday' ? ' • repeats annually' : ''}', style: GoogleFonts.inter(fontSize: 11, color: AndroidTheme.textTertiary)),
          if (event.startTime != null)
            Text(
              '${event.startTime}${event.endTime != null ? ' → ${event.endTime}' : ''}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AndroidTheme.textSecondary,
              ),
            ),
          if (event.linkedJobTitle != null)
            Text(
              '🔗 ${event.linkedJobTitle}',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AndroidTheme.primary,
              ),
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _kCategoryLabels[event.category] ?? event.category,
              style: GoogleFonts.inter(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _confirmDelete(context, ref),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: AndroidTheme.textTertiary,
            ),
          ),
        ],
      ),
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
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
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
  final String initialType;
  const _EventFormSheet({required this.ref, this.existing, this.initialType = 'event'});

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _startTime;
  late final TextEditingController _endTime;
  late String _category;
  late String _itemType;
  late final TextEditingController _contactInfo;
  late final TextEditingController _attachmentPath;
  bool _isDone = false;
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
    _category    = e?.category ?? (widget.initialType == 'birthday' ? 'occasion' : 'other');
    _itemType = e?.itemType ?? widget.initialType;
    _contactInfo = TextEditingController(text: e?.contactInfo ?? '');
    _attachmentPath = TextEditingController(text: e?.attachmentPath ?? '');
    _isDone = e?.isDone ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _startTime.dispose();
    _endTime.dispose();
    _contactInfo.dispose();
    _attachmentPath.dispose();
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
      description:    _description.text.trim().isEmpty
          ? null
          : _description.text.trim(),
      date:           dateKey(selected),
      startTime:      _startTime.text.trim().isEmpty
          ? null
          : _startTime.text.trim(),
      endTime:        _endTime.text.trim().isEmpty
          ? null
          : _endTime.text.trim(),
      category:       _category,
      itemType:       _itemType,
      contactInfo:    _contactInfo.text.trim().isEmpty ? null : _contactInfo.text.trim(),
      attachmentPath: _attachmentPath.text.trim().isEmpty ? null : _attachmentPath.text.trim(),
      isDone:         _isDone,
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
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Calendar Item' : 'Add ${_itemType[0].toUpperCase()}${_itemType.substring(1)}',
              style: GoogleFonts.inter(
                  fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<String>(
              value: _itemType,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'birthday', child: Text('Birthday')),
                DropdownMenuItem(value: 'task', child: Text('Task')),
                DropdownMenuItem(value: 'event', child: Text('Event')),
              ],
              onChanged: isEdit ? null : (v) => setState(() => _itemType = v ?? _itemType),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _title,
              decoration: InputDecoration(labelText: _itemType == 'birthday' ? 'Name *' : _itemType == 'task' ? 'Task Title *' : 'Event Title *'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(labelText: 'Category'),
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
                      labelText: 'Start',
                      suffixIcon:
                          Icon(Icons.access_time_rounded, size: 18),
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
                      labelText: 'End',
                      suffixIcon:
                          Icon(Icons.access_time_rounded, size: 18),
                    ),
                    onTap: () => _pickTime(_endTime),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            if (_itemType == 'birthday') ...[
              TextField(
                controller: _contactInfo,
                decoration: const InputDecoration(labelText: 'Contact / Gift ideas / Gift link'),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
            ],
            if (_itemType == 'task') ...[
              TextField(
                controller: _attachmentPath,
                decoration: const InputDecoration(labelText: 'Optional Attachment Path'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Complete'),
                value: _isDone,
                onChanged: (v) => setState(() => _isDone = v),
              ),
              const SizedBox(height: 12),
            ],

            jobsAsync.when(
              data: (jobs) => jobs.isEmpty
                  ? const SizedBox.shrink()
                  : DropdownButtonFormField<Job?>(
                      value: _linkedJob,
                      decoration: const InputDecoration(
                          labelText: '🔗 Link to Job'),
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