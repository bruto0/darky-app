import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';

/// Currently selected schedule day, shared by [ScheduleSection] and
/// [ScheduleFab].
///
/// The section owns the week strip and writes this value; the FAB is a
/// separate overlay and reads it to know which day to refresh. The initial
/// value is the branch-local today (never the device date).
final scheduleSelectedDayProvider = StateProvider<DateTime>((ref) {
  final clock = ref.watch(branchClockProvider);
  final today = clock.dayStart(clock.branchNow());
  return today;
});
