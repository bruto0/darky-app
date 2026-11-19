import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/providers.dart';
import '../../core/data/data_providers.dart';
import '../../core/models/schedule_item.dart';
import '../../core/network/api_failure.dart';
import '../../core/time/branch_clock.dart';
import '../../core/ui/theme.dart';
import 'schedule_card.dart';
import 'schedule_filters.dart';
import 'schedule_format.dart';
import 'schedule_providers.dart';

/// Schedule block of the "Абонемент" screen.
///
/// The widget builds **slivers** and must be inserted directly into the home
/// `CustomScrollView.slivers` (or another sliver list). It must not be wrapped
/// in a box widget, `SingleChildScrollView` or a nested `ListView`: the day
/// list is a `SliverList` and grows to its full height inside the parent
/// scroll.
class ScheduleSection extends ConsumerStatefulWidget {
  const ScheduleSection({super.key, this.bottomPadding = 24});

  /// Bottom padding of the list/empty/error slivers. The parent may increase
  /// it to reserve room for the floating navigation or the refresh FAB.
  final double bottomPadding;

  @override
  ConsumerState<ScheduleSection> createState() => _ScheduleSectionState();
}

class _ScheduleSectionState extends ConsumerState<ScheduleSection> {
  static const double _horizontal = 20;

  final GlobalKey _weekKey = GlobalKey();
  ScheduleFilters _filters = ScheduleFilters.none;

  DateTime get _selectedDay => ref.read(scheduleSelectedDayProvider);

  void _selectDay(DateTime day) {
    final clock = ref.read(branchClockProvider);
    final normalized = clock.dayStart(day);
    final current = ref.read(scheduleSelectedDayProvider);
    if (clock.isSameDay(normalized, current)) return;
    ref.read(scheduleSelectedDayProvider.notifier).state = normalized;
  }

  void _shiftWeek(int days) {
    _selectDay(ref.read(scheduleSelectedDayProvider).add(Duration(days: days)));
  }

  void _retry() {
    ref.invalidate(scheduleDayProvider(_selectedDay));
  }

  Future<void> _pickHall() async {
    final unfiltered =
        ref.read(scheduleDayProvider(_selectedDay)).valueOrNull ??
            const <ScheduleItem>[];
    final choice = await showModalBottomSheet<_FilterChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        title: 'Зал',
        options: scheduleHallOptions(unfiltered),
        selected: _filters.hall,
      ),
    );
    if (!mounted || choice == null) return;
    setState(() => _filters = _filters.withHall(choice.value));
  }

  Future<void> _pickTeacher() async {
    final unfiltered =
        ref.read(scheduleDayProvider(_selectedDay)).valueOrNull ??
            const <ScheduleItem>[];
    final choice = await showModalBottomSheet<_FilterChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _FilterSheet(
        title: 'Преподаватель',
        options: scheduleTeacherOptions(unfiltered),
        selected: _filters.teacher,
      ),
    );
    if (!mounted || choice == null) return;
    setState(() => _filters = _filters.withTeacher(choice.value));
  }

  void _clearFilters() {
    if (!_filters.isActive) return;
    setState(() => _filters = ScheduleFilters.none);
  }

  Future<void> _scrollToWeek() async {
    final target = _weekKey.currentContext;
    if (target == null) return;
    await Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final clock = ref.watch(branchClockProvider);
    final selectedDay = ref.watch(scheduleSelectedDayProvider);
    final today = clock.dayStart(clock.branchNow());
    final dayState = ref.watch(scheduleDayProvider(selectedDay));
    final ownClientId =
        ref.watch(sessionControllerProvider).valueOrNull?.clientId;
    final unfiltered = dayState.valueOrNull ?? const <ScheduleItem>[];
    final filtered = applyScheduleFilters(unfiltered, _filters);
    final filteredEmpty = unfiltered.isNotEmpty && filtered.isEmpty;

    return DecoratedSliver(
      decoration: BoxDecoration(color: palette.scheduleBg),
      sliver: SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_horizontal, 18, _horizontal, 0),
              child: _SectionHeader(
                dateLabel: scheduleDayTitle(selectedDay, today, clock),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_horizontal, 12, _horizontal, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _FilterPill(
                      label: 'Зал',
                      value: _filters.hall ?? 'Все',
                      onTap: _pickHall,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _FilterPill(
                      label: 'Преподаватель',
                      value: _filters.teacher ?? 'Все',
                      onTap: _pickTeacher,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              key: _weekKey,
              padding: const EdgeInsets.fromLTRB(_horizontal, 10, _horizontal, 10),
              child: _buildWeekStrip(
                palette: palette,
                clock: clock,
                selectedDay: selectedDay,
                today: today,
              ),
            ),
          ),
          ..._contentSlivers(
            dayState: dayState,
            filtered: filtered,
            filteredEmpty: filteredEmpty,
            clock: clock,
            palette: palette,
            ownClientId: ownClientId,
          ),
        ],
      ),
    );
  }

  List<Widget> _contentSlivers({
    required AsyncValue<List<ScheduleItem>> dayState,
    required List<ScheduleItem> filtered,
    required bool filteredEmpty,
    required BranchClock clock,
    required AppPalette palette,
    required int? ownClientId,
  }) {
    final padding = EdgeInsets.fromLTRB(
      _horizontal,
      2,
      _horizontal,
      widget.bottomPadding,
    );

    return dayState.when(
      skipLoadingOnRefresh: false,
      loading: () => [
        SliverPadding(
          padding: padding,
          sliver: const SliverToBoxAdapter(child: _ScheduleSkeleton()),
        ),
      ],
      error: (error, _) => [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: _ScheduleError(
              reason: _errorReason(error),
              onRetry: _retry,
            ),
          ),
        ),
      ],
      data: (_) {
        if (filtered.isEmpty) {
          return [
            SliverPadding(
              padding: padding,
              sliver: SliverToBoxAdapter(
                child: _ScheduleEmpty(
                  filtered: filteredEmpty,
                  onResetFilters: _clearFilters,
                  onPickAnotherDay: _scrollToWeek,
                ),
              ),
            ),
          ];
        }
        return [
          SliverPadding(
            padding: padding,
            sliver: SliverList.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == filtered.length - 1 ? 0 : 8,
                ),
                child: ScheduleCard(
                  item: filtered[index],
                  clock: clock,
                  clientId: ownClientId,
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildWeekStrip({
    required AppPalette palette,
    required BranchClock clock,
    required DateTime selectedDay,
    required DateTime today,
  }) {
    final weekStart = scheduleWeekStart(selectedDay);
    final days = [
      for (var index = 0; index < 7; index++)
        weekStart.add(Duration(days: index)),
    ];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -80) {
          _shiftWeek(7);
        } else if (velocity > 80) {
          _shiftWeek(-7);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.line),
        ),
        child: Row(
          children: [
            _WeekArrow(
              icon: Icons.chevron_left,
              tooltip: 'Предыдущая неделя',
              onTap: () => _shiftWeek(-7),
            ),
            for (final day in days)
              Expanded(
                child: _WeekDay(
                  day: day,
                  selected: clock.isSameDay(day, selectedDay),
                  today: clock.isSameDay(day, today),
                  weekday: scheduleWeekdayShort(day, clock),
                  onTap: () => _selectDay(day),
                ),
              ),
            _WeekArrow(
              icon: Icons.chevron_right,
              tooltip: 'Следующая неделя',
              onTap: () => _shiftWeek(7),
            ),
          ],
        ),
      ),
    );
  }

  static String _errorReason(Object? error) {
    return switch (error) {
      NetworkFailure() => 'Проверьте соединение и попробуйте снова',
      TimeoutFailure() => 'Сервер долго не отвечает',
      UnauthorizedFailure() => 'Сессия истекла, войдите снова',
      VendorFailure(:final message) => message,
      ApiFailure(:final message) => message,
      _ => 'Попробуйте ещё раз',
    };
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text('Расписание', style: text.titleLarge),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 13,
                color: palette.muted,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: text.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label: $value',
      child: Material(
        color: palette.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
          side: BorderSide(color: palette.line),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            child: Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '$label · ',
                          style: text.bodySmall?.copyWith(color: palette.muted),
                        ),
                        TextSpan(
                          text: value,
                          style: text.bodySmall?.copyWith(
                            color: palette.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: palette.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Semantics(
      button: true,
      label: tooltip,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: SizedBox(
            width: 32,
            height: 48,
            child: Icon(icon, size: 20, color: palette.muted),
          ),
        ),
      ),
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.day,
    required this.selected,
    required this.today,
    required this.weekday,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final bool today;
  final String weekday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    final foreground = selected ? palette.bg : palette.ink;
    final secondary = selected
        ? palette.bg.withValues(alpha: 0.7)
        : palette.muted;
    final dot = selected ? palette.bg : palette.pink;

    return Semantics(
      button: true,
      selected: selected,
      label: '${day.day} ${_monthLabel(day)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 52,
            decoration: BoxDecoration(
              color: selected ? palette.ink : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  weekday,
                  maxLines: 1,
                  style: text.labelSmall?.copyWith(
                    color: secondary,
                    fontSize: 9.5,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${day.day}',
                  maxLines: 1,
                  style: text.titleMedium?.copyWith(
                    color: foreground,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: today ? dot : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _monthLabel(DateTime day) {
    const months = [
      'января',
      'февраля',
      'марта',
      'апреля',
      'мая',
      'июня',
      'июля',
      'августа',
      'сентября',
      'октября',
      'ноября',
      'декабря',
    ];
    return months[(day.month - 1) % 12];
  }
}

class _FilterChoice {
  const _FilterChoice(this.value);

  final String? value;
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.title,
    required this.options,
    required this.selected,
  });

  final String title;
  final List<String> options;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(title, style: text.titleLarge),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 12),
                children: [
                  _FilterRow(
                    label: 'Все',
                    selected: selected == null,
                    onTap: () => Navigator.pop(context, const _FilterChoice(null)),
                  ),
                  for (final option in options)
                    _FilterRow(
                      label: option,
                      selected: option == selected,
                      onTap: () =>
                          Navigator.pop(context, _FilterChoice(option)),
                    ),
                ],
              ),
            ),
            if (options.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Text(
                  'На выбранный день вариантов нет',
                  style: text.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: text.bodyLarge?.copyWith(
                  color: selected ? palette.pinkDeep : palette.ink2,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check, size: 20, color: palette.pinkDeep),
          ],
        ),
      ),
    );
  }
}

class _ScheduleError extends StatelessWidget {
  const _ScheduleError({required this.reason, required this.onRetry});

  final String reason;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.cloud_off_outlined,
      title: 'Расписание не загрузилось',
      message: reason,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onRetry,
          child: const Text('Повторить'),
        ),
      ),
    );
  }
}

class _ScheduleEmpty extends StatelessWidget {
  const _ScheduleEmpty({
    required this.filtered,
    required this.onResetFilters,
    required this.onPickAnotherDay,
  });

  final bool filtered;
  final VoidCallback onResetFilters;
  final VoidCallback onPickAnotherDay;

  @override
  Widget build(BuildContext context) {
    return _StateCard(
      icon: Icons.event_busy_outlined,
      title: filtered
          ? 'Нет занятий с выбранными фильтрами'
          : 'На этот день занятий нет',
      message: filtered
          ? 'Сбросьте фильтры или выберите другой день.'
          : 'Посмотрите другой день недели.',
      child: Column(
        children: [
          if (filtered)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onResetFilters,
                child: const Text('Сбросить фильтры'),
              ),
            ),
          if (filtered) const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onPickAnotherDay,
              child: const Text('Выбрать другой день'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: palette.line),
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.pinkSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: palette.pinkDeep),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: text.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ScheduleSkeleton extends StatefulWidget {
  const _ScheduleSkeleton();

  @override
  State<_ScheduleSkeleton> createState() => _ScheduleSkeletonState();
}

class _ScheduleSkeletonState extends State<_ScheduleSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = 0.45 + 0.25 * Curves.easeInOut.transform(_controller.value);
        return Opacity(
          opacity: opacity,
          child: Column(
            children: [
              for (var index = 0; index < 5; index++)
                Container(
                  height: index.isEven ? 88 : 76,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: palette.line.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 16,
                        decoration: BoxDecoration(
                          color: palette.muted.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: palette.muted.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 120,
                              height: 11,
                              decoration: BoxDecoration(
                                color: palette.muted.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
