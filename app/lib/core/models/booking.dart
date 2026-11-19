class Booking {
  const Booking({
    required this.id,
    this.title,
    this.hallName,
    this.teacherName,
    this.startsAt,
    this.status,
    this.type = 0,
    this.minutesBegin,
    this.minutesEnd,
    this.date,
    this.branchName,
    this.clientName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    final branch = json['branch'] is Map ? json['branch'] as Map : const {};
    final client = json['client'] is Map ? json['client'] as Map : const {};
    return Booking(
      id: '${json['id'] ?? ''}',
      title: (json['name'] ?? json['title'] ?? json['typeTitle'])?.toString(),
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] as String?) ?? _teacherName(teacher),
      startsAt: _date(json['startsAt'] ?? json['date']),
      status: json['status']?.toString(),
      type: (json['type'] as num?)?.toInt() ?? 0,
      minutesBegin: (json['minutesBegin'] as num?)?.toInt(),
      minutesEnd: (json['minutesEnd'] as num?)?.toInt(),
      date: _date(json['date'] ?? json['dateBegin']),
      branchName: (json['branchName'] ?? branch['name'])?.toString(),
      clientName: (json['clientName'] ?? _personName(client))?.toString(),
    );
  }

  final String id;
  final String? title;
  final String? hallName;
  final String? teacherName;
  final DateTime? startsAt;
  final String? status;
  final int type;
  final int? minutesBegin;
  final int? minutesEnd;
  final DateTime? date;
  final String? branchName;
  final String? clientName;

  bool get isRent => type == 2;
  bool get isIndividual => type == 1;

  static String? _teacherName(Map teacher) {
    final last = (teacher['lastName'] ?? '').toString().trim();
    final first = (teacher['name'] ?? '').toString().trim();
    final parts = [first, last].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
  }

  static String? _personName(Map person) {
    final last = (person['lastName'] ?? '').toString().trim();
    final first = (person['name'] ?? '').toString().trim();
    final parts = [last, first].where((p) => p.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' ');
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
