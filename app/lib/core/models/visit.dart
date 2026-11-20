class Visit {
  const Visit({
    required this.id,
    this.title,
    this.hallName,
    this.teacherName,
    this.visitedAt,
    this.status,
    this.targetName,
    this.targetEntity,
    this.targetId,
    this.substituteTeacherNames = const [],
    this.substituteText,
    this.teacherNames,
    this.serviceNumber,
    this.branchName,
    this.byAccount,
    this.durationMinutes,
    this.styleColor,
    this.level,
    this.minutesBegin,
    this.minutesEnd,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    final target = json['target'] is Map ? json['target'] as Map : const {};
    final service = json['service'] is Map ? json['service'] as Map : const {};
    final branch = json['branch'] is Map ? json['branch'] as Map : const {};
    final style = target['style'] is Map
        ? target['style'] as Map
        : json['style'] is Map
            ? json['style'] as Map
            : const {};
    final teachers = target['teachers'] is List
        ? target['teachers']
        : json['teachers'] is List
            ? json['teachers']
            : const [];
    final targetTeachers = [
      if (target['teacher1'] is Map) target['teacher1'],
      if (target['teacher2'] is Map) target['teacher2'],
    ];
    final targetName = style['name']?.toString();
    final level = target['level']?.toString();
    final targetEntity = target['entity']?.toString();
    final individualTeacher = targetEntity == 'teacher'
        ? _shortName(target)
        : null;
    final teacherNames = individualTeacher != null
        ? <String>[individualTeacher]
        : _teacherList(teachers.isNotEmpty ? teachers : targetTeachers);
    final rawTitle = targetEntity == 'teacher'
        ? (json['name'] ?? json['title'])
        : (json['name'] ?? json['title'] ?? target['name'] ?? target['title']);

    return Visit(
      id: '${json['id'] ?? ''}',
      title: targetName ??
          rawTitle?.toString() ??
          (targetEntity == 'teacher' ? 'Индивидуальное занятие' : null),
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] as String?) ??
          individualTeacher ??
          _teacherName(teacher),
      visitedAt: _date(json['visit_date'] ?? json['visitDate'] ?? json['visitedAt']),
      status: json['status']?.toString(),
      targetName: (json['targetName'] ?? targetName)?.toString(),
      targetEntity: targetEntity,
      targetId: _int(target['id']) ?? _int(json['targetId']),
      teacherNames: teacherNames,
      serviceNumber: _int(service['number']) ??
          _int(json['service']) ??
          _int(json['serviceNumber']),
      branchName: (json['branchName'] ?? branch['name'])?.toString(),
      byAccount: json['byAccount'] == true,
      durationMinutes: _int(json['duration']),
      styleColor: style['color']?.toString(),
      level: level,
      minutesBegin: _int(json['minutesBegin']),
      minutesEnd: _int(json['minutesEnd']),
    );
  }

  final String id;
  final String? title;
  final String? hallName;
  final String? teacherName;
  final DateTime? visitedAt;
  final String? status;
  final String? targetName;
  final String? targetEntity;
  final int? targetId;
  final List<String> substituteTeacherNames;
  final String? substituteText;
  final List<String>? teacherNames;
  final int? serviceNumber;
  final String? branchName;
  final bool? byAccount;
  final int? durationMinutes;
  final String? styleColor;
  final String? level;
  final int? minutesBegin;
  final int? minutesEnd;

  Visit withSubstitutes({
    required List<String> names,
    String? text,
  }) {
    return Visit(
      id: id,
      title: title,
      hallName: hallName,
      teacherName: teacherName,
      visitedAt: visitedAt,
      status: status,
      targetName: targetName,
      targetEntity: targetEntity,
      targetId: targetId,
      substituteTeacherNames: names,
      substituteText: text,
      teacherNames: teacherNames,
      serviceNumber: serviceNumber,
      branchName: branchName,
      byAccount: byAccount,
      durationMinutes: durationMinutes,
      styleColor: styleColor,
      level: level,
      minutesBegin: minutesBegin,
      minutesEnd: minutesEnd,
    );
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String? _shortName(Map person) {
    final first = (person['name'] ?? '').toString().trim();
    final last = (person['lastName'] ?? '').toString().trim();
    final parts = [first, last].where((part) => part.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String? _teacherName(Map teacher) {
    final last = (teacher['lastName'] ?? '').toString().trim();
    final first = (teacher['name'] ?? '').toString().trim();
    final parts = [first, last].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  static List<String>? _teacherList(List teachers) {
    final names = <String>[];
    for (final item in teachers) {
      if (item is Map) {
        final name = _teacherName(item);
        if (name != null) names.add(name);
      }
    }
    return names.isEmpty ? null : names;
  }

  static DateTime? _date(Object? value) {
    if (value is num) {
      final seconds = value > 1000000000000 ? value ~/ 1000 : value;
      return DateTime.fromMillisecondsSinceEpoch(
        seconds.toInt() * 1000,
        isUtc: true,
      );
    }
    return DateTime.tryParse('${value ?? ''}');
  }
}
