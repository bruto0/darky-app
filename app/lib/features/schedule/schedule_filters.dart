import '../../core/models/schedule_item.dart';

/// Client-side schedule filters. `null` means "Все" (no restriction).
///
/// Options are always derived from the *unfiltered* day returned by the API;
/// filtering never reloads the day and never resets on day/week changes.
class ScheduleFilters {
  const ScheduleFilters({this.hall, this.teacher});

  static const ScheduleFilters none = ScheduleFilters();

  final String? hall;
  final String? teacher;

  bool get isActive => hall != null || teacher != null;

  ScheduleFilters withHall(String? value) =>
      ScheduleFilters(hall: value, teacher: teacher);

  ScheduleFilters withTeacher(String? value) =>
      ScheduleFilters(hall: hall, teacher: value);

  bool matches(ScheduleItem item) {
    if (hall != null && item.hallName != hall) return false;
    if (teacher != null && item.teacherName != teacher) return false;
    return true;
  }

  @override
  bool operator ==(Object other) =>
      other is ScheduleFilters &&
      other.hall == hall &&
      other.teacher == teacher;

  @override
  int get hashCode => Object.hash(hall, teacher);

  @override
  String toString() => 'ScheduleFilters(hall: $hall, teacher: $teacher)';
}

/// Applies the hall/teacher filters to an already loaded day.
///
/// The returned list keeps the API order (time, type, title).
List<ScheduleItem> applyScheduleFilters(
  List<ScheduleItem> items,
  ScheduleFilters filters,
) {
  if (!filters.isActive) return List<ScheduleItem>.unmodifiable(items);
  return List<ScheduleItem>.unmodifiable(items.where(filters.matches));
}

/// Distinct non-empty hall names in the order they first appear in the day.
List<String> scheduleHallOptions(Iterable<ScheduleItem> items) =>
    _distinctValues(items.map((item) => item.hallName));

/// Distinct non-empty teacher names in the order they first appear in the day.
List<String> scheduleTeacherOptions(Iterable<ScheduleItem> items) =>
    _distinctValues(items.map((item) => item.teacherName));

List<String> _distinctValues(Iterable<String?> values) {
  final seen = <String>{};
  final result = <String>[];
  for (final raw in values) {
    final value = raw?.trim();
    if (value == null || value.isEmpty) continue;
    if (seen.add(value)) result.add(value);
  }
  return List<String>.unmodifiable(result);
}
