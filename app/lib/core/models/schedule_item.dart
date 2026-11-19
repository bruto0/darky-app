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
    this.color,
    this.regular,
    this.dateEnd,
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
    final groupTeacher1 =
        group['teacher1'] is Map ? group['teacher1'] as Map : const {};
    final groupTeacher2 =
        group['teacher2'] is Map ? group['teacher2'] as Map : const {};
    final style = json['style'] is Map ? json['style'] as Map : const {};
    final groupStyle =
        group['style'] is Map ? group['style'] as Map : const {};
    final name = (json['name'] ?? json['title'])?.toString();
    final styleName = (style['name'] ?? groupStyle['name'])?.toString();
    final groupName = (group['name'] ?? group['webHeader'])?.toString();
    final teacherName = _teacherName(teacher) ??
        _teacherName(teacher1) ??
        _teacherName(teacher2) ??
        _teacherName(groupTeacher1) ??
        _teacherName(groupTeacher2);

    return ScheduleItem(
      id: '${json['id'] ?? ''}',
      type: _int(json['type']) ?? 0,
      title: name ?? styleName ?? groupName ?? 'Занятие',
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] as String?) ?? teacherName,
      clientId: _int(json['clientId']) ?? _int(client['id']),
      clientName: (json['clientName'] ?? _personName(client))?.toString(),
      startsAt: _date(json['startsAt'] ?? json['date']),
      endsAt: _date(json['endsAt']),
      isMine: json['isMine'] == true,
      typeTitle: json['typeTitle']?.toString(),
      minutesBegin: _int(json['minutesBegin']),
      minutesEnd: _int(json['minutesEnd']),
      date: _date(json['date'] ?? json['dateBegin']),
      styleName: styleName,
      groupLevel: group['level']?.toString(),
      branchName: (json['branchName'] ?? json['branch']?['name'])?.toString(),
      stickerName: json['stickerName']?.toString(),
      stickerColor: json['stickerColor']?.toString(),
      changeText: json['changeText']?.toString(),
      color: json['color']?.toString(),
      regular: json['regular'] == true,
      dateEnd: _date(json['dateEnd']),
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
  final String? color;
  final bool? regular;
  final DateTime? dateEnd;

  bool get isGroup => type == 0;
  bool get isIndividual => type == 1;
  bool get isRent => type == 2;

  ScheduleItem copyWith({
    String? title,
    String? stickerName,
    String? stickerColor,
    String? changeText,
    String? teacherName,
    String? clientName,
    String? styleName,
    bool? isMine,
    bool clearClientName = false,
    bool clearTeacherName = false,
    bool clearStyleName = false,
    bool clearChangeText = false,
  }) {
    return ScheduleItem(
      id: id,
      type: type,
      title: title ?? this.title,
      hallName: hallName,
      teacherName: clearTeacherName
          ? null
          : (teacherName ?? this.teacherName),
      clientId: clientId,
      clientName: clearClientName ? null : (clientName ?? this.clientName),
      startsAt: startsAt,
      endsAt: endsAt,
      isMine: isMine ?? this.isMine,
      typeTitle: typeTitle,
      minutesBegin: minutesBegin,
      minutesEnd: minutesEnd,
      date: date,
      styleName: clearStyleName ? null : (styleName ?? this.styleName),
      groupLevel: groupLevel,
      branchName: branchName,
      stickerName: stickerName ?? this.stickerName,
      stickerColor: stickerColor ?? this.stickerColor,
      changeText: clearChangeText ? null : (changeText ?? this.changeText),
      color: color,
      regular: regular,
      dateEnd: dateEnd,
    );
  }

  /// Removes all vendor PII/style data from a foreign individual/rent item.
  ScheduleItem sanitizedForeign() {
    return copyWith(
      title: isRent ? 'аренда' : 'индив',
      clientName: null,
      clearClientName: true,
      clearTeacherName: true,
      clearStyleName: true,
      clearChangeText: true,
    );
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
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
