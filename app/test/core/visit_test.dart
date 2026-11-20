import 'package:dance/core/models/visit.dart';
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
}
