import 'package:dance/core/models/visit.dart';
import 'package:dance/features/visits/visit_history_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('individual visit uses name + lastName for its teacher', () {
    final visit = Visit.fromJson({
      'id': 1,
      'visitDate': 1790000000,
      'target': {
        'id': 10,
        'entity': 'teacher',
        'name': 'Андрей',
        'lastName': 'Чистяков',
        'middleName': 'Петрович',
      },
      'byAccount': true,
    });

    expect(visit.teacherNames, ['Андрей Чистяков']);
    expect(visit.teacherName, 'Андрей Чистяков');
    expect(visit.title, 'Индивидуальное занятие');
  });

  test('group visit appends level to the title like schedule', () {
    final visit = Visit.fromJson({
      'id': 2,
      'visitDate': 1790000000,
      'target': {
        'id': 20,
        'entity': 'group',
        'level': 'Intermediate',
        'style': {'name': 'Бачата'},
      },
      'byAccount': true,
    });

    expect(visitTitle(visit), 'Бачата Intermediate');
  });
}
