class ScheduleItem {
  const ScheduleItem({
    required this.id,
    required this.type,
    required this.title,
    this.hallName,
    this.teacherName,
    this.clientId,
    this.clientName,
    this.startsAt,
    this.endsAt,
    this.isMine = false,
    this.typeTitle,
    this.minutesBegin,
    this.minutesEnd,
    this.date,
    this.styleName,
    this.groupLevel,
    this.branchName,
    this.stickerName,
    this.stickerColor,
    this.changeText,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    final teacher1 =
        json['teacher1'] is Map ? json['teacher1'] as Map : const {};
    final teacher2 =
        json['teacher2'] is Map ? json['teacher2'] as Map : const {};
    final client = json['client'] is Map ? json['client'] as Map : const {};
    final group = json['group'] is Map ? json['group'] as Map : const {};
    final style = json['style'] is Map ? json['style'] as Map : const {};
    final groupStyle =
        group['style'] is Map ? group['style'] as Map : const {};
    final name = (json['name'] ?? json['title'])?.toString();
    final styleName = (style['name'] ?? groupStyle['name'])?.toString();
    final groupName = (group['name'] ?? group['webHeader'])?.toString();
    final teacherName = _teacherName(teacher) ??
        _teacherName(teacher1) ??
        _teacherName(teacher2);

    return ScheduleItem(
      id: '${json['id'] ?? ''}',
      type: (json['type'] as num?)?.toInt() ?? 0,
      title: name ?? styleName ?? groupName ?? 'Занятие',
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] as String?) ?? teacherName,
      clientId: ((json['clientId'] ?? client['id']) as num?)?.toInt(),
      clientName: (json['clientName'] ?? _personName(client))?.toString(),
      startsAt: _date(json['startsAt'] ?? json['date']),
      endsAt: _date(json['endsAt']),
      isMine: json['isMine'] == true,
      typeTitle: json['typeTitle']?.toString(),
      minutesBegin: (json['minutesBegin'] as num?)?.toInt(),
      minutesEnd: (json['minutesEnd'] as num?)?.toInt(),
      date: _date(json['date'] ?? json['dateBegin']),
      styleName: styleName,
      groupLevel: group['level']?.toString(),
      branchName: (json['branchName'] ?? json['branch']?['name'])?.toString(),
      stickerName: json['stickerName']?.toString(),
      stickerColor: json['stickerColor']?.toString(),
      changeText: json['changeText']?.toString(),
    );
  }

  final String id;

  /// 0 — group, 1 — individual, 2 — rent.
  final int type;
  final String title;
  final String? hallName;
  final String? teacherName;
  final int? clientId;
  final String? clientName;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool isMine;
  final String? typeTitle;
  final int? minutesBegin;
  final int? minutesEnd;
  final DateTime? date;
  final String? styleName;
  final String? groupLevel;
  final String? branchName;
  final String? stickerName;
  final String? stickerColor;
  final String? changeText;

  bool get isGroup => type == 0;
  bool get isIndividual => type == 1;
  bool get isRent => type == 2;

  ScheduleItem copyWith({
    String? stickerName,
    String? stickerColor,
    String? changeText,
    String? teacherName,
    bool? isMine,
  }) {
    return ScheduleItem(
      id: id,
      type: type,
      title: title,
      hallName: hallName,
      teacherName: teacherName ?? this.teacherName,
      clientId: clientId,
      clientName: clientName,
      startsAt: startsAt,
      endsAt: endsAt,
      isMine: isMine ?? this.isMine,
      typeTitle: typeTitle,
      minutesBegin: minutesBegin,
      minutesEnd: minutesEnd,
      date: date,
      styleName: styleName,
      groupLevel: groupLevel,
      branchName: branchName,
      stickerName: stickerName ?? this.stickerName,
      stickerColor: stickerColor ?? this.stickerColor,
      changeText: changeText ?? this.changeText,
    );
  }

  static String? _teacherName(Map teacher) {
    final last = (teacher['lastName'] ?? '').toString().trim();
    final first = (teacher['name'] ?? '').toString().trim();
    final middle = (teacher['middleName'] ?? '').toString().trim();
    final parts = [first, last, middle].where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
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
