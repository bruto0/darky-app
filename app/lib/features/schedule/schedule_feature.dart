/// Public entry point of the schedule feature.
///
/// Integration contract for the home screen:
///
/// ```dart
/// Stack(
///   children: [
///     CustomScrollView(
///       slivers: [
///         // profile / accounts slivers...
///         const ScheduleSection(),
///       ],
///     ),
///     const Positioned.fill(child: ScheduleFab()),
///   ],
/// )
/// ```
///
/// `ScheduleSection` returns slivers and must not be wrapped in a box or a
/// nested scrollable. `ScheduleFab` is an independent overlay that reads the
/// day selected by the section through `scheduleSelectedDayProvider`.
library;

export 'schedule_card.dart';
export 'schedule_fab.dart';
export 'schedule_filters.dart';
export 'schedule_format.dart';
export 'schedule_page.dart';
export 'schedule_providers.dart';
export 'schedule_section.dart';
