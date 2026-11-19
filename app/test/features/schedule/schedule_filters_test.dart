import 'package:dance/features/schedule/schedule_filters.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

void main() {
  final items = [
    scheduleItem(id: '1', hallName: 'Зал 1', teacherName: 'Мария'),
    scheduleItem(id: '2', hallName: 'Зал 2'),
    scheduleItem(id: '3', hallName: 'Зал 1', teacherName: 'Олег'),
    scheduleItem(id: '4', hallName: null, teacherName: 'Мария'),
    scheduleItem(id: '5', hallName: '  ', teacherName: ' '),
  ];

  test('option lists use unfiltered items, order and deduplication', () {
    expect(scheduleHallOptions(items), ['Зал 1', 'Зал 2']);
    expect(scheduleTeacherOptions(items), ['Мария', 'Олег']);
  });

  test('no filters returns the full day in API order', () {
    final filtered = applyScheduleFilters(items, ScheduleFilters.none);
    expect(filtered.map((item) => item.id), ['1', '2', '3', '4', '5']);
  });

  test('filters by hall', () {
    final filtered = applyScheduleFilters(
      items,
      const ScheduleFilters(hall: 'Зал 1'),
    );
    expect(filtered.map((item) => item.id), ['1', '3']);
  });

  test('filters by teacher', () {
    final filtered = applyScheduleFilters(
      items,
      const ScheduleFilters(teacher: 'Мария'),
    );
    expect(filtered.map((item) => item.id), ['1', '4']);
  });

  test('hall and teacher filters combine with AND', () {
    final filtered = applyScheduleFilters(
      items,
      const ScheduleFilters(hall: 'Зал 1', teacher: 'Мария'),
    );
    expect(filtered.map((item) => item.id), ['1']);
  });

  test('no matches returns an empty list', () {
    expect(
      applyScheduleFilters(
        items,
        const ScheduleFilters(hall: 'Нет такого зала'),
      ),
      isEmpty,
    );
  });

  test('withHall keeps teacher and vice versa', () {
    const filters = ScheduleFilters(hall: 'Зал 1', teacher: 'Мария');
    expect(filters.withHall('Зал 2').teacher, 'Мария');
    expect(filters.withTeacher('Олег').hall, 'Зал 1');
    expect(filters.withHall(null), const ScheduleFilters(teacher: 'Мария'));
    expect(const ScheduleFilters().isActive, isFalse);
  });
}
