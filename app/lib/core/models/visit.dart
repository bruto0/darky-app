class Visit {
  const Visit({
    required this.id,
    this.title,
    this.hallName,
    this.teacherName,
    this.visitedAt,
    this.status,
    this.targetName,
    this.teacherNames,
    this.serviceNumber,
    this.branchName,
    this.byAccount,
    this.durationMinutes,
    this.styleColor,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    final target = json['target'] is Map ? json['target'] as Map : const {};
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

    return Visit(
      id: '${json['id'] ?? ''}',
      title: (json['name'] ??
              json['title'] ??
              target['name'] ??
              target['title'])
          ?.toString(),
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] as String?) ?? _teacherName(teacher),
      visitedAt: _date(json['visit_date'] ?? json['visitDate'] ?? json['visitedAt']),
      status: json['status']?.toString(),
      targetName: (json['targetName'] ?? target['name'])?.toString(),
      teacherNames: _teacherList(teachers),
      serviceNumber: (json['service'] as num?)?.toInt() ??
          (json['serviceNumber'] as num?)?.toInt(),
      branchName: (json['branchName'] ?? branch['name'])?.toString(),
      byAccount: json['byAccount'] == true,
      durationMinutes: (json['duration'] as num?)?.toInt(),
      styleColor: style['color']?.toString(),
    );
  }

  final String id;
  final String? title;
  final String? hallName;
  final String? teacherName;
  final DateTime? visitedAt;
  final String? status;
  final String? targetName;
  final List<String>? teacherNames;
  final int? serviceNumber;
  final String? branchName;
  final bool? byAccount;
  final int? durationMinutes;
  final String? styleColor;

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
