import 'package:dance/core/models/schedule_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('group teacher names use name + lastName without middleName', () {
    final item = ScheduleItem.fromJson({
      'id': 343,
      'type': 0,
      'minutesBegin': 840,
      'minutesEnd': 900,
      'hall': {'name': 'Большой зал'},
      'group': {
        'style': {'name': 'Бачата'},
        'teacher1': {
          'id': 1,
          'name': 'Диего',
          'lastName': 'Кальдерон',
          'middleName': 'Хосе',
        },
        'teacher2': {
          'id': 2,
          'name': 'Наталья',
          'lastName': 'Губина',
          'middleName': 'Леонидовна',
        },
      },
    });

    expect(item.mainTeacherNames, ['Диего Кальдерон', 'Наталья Губина']);
    expect(item.teacherName, 'Диего Кальдерон');
  });
}
