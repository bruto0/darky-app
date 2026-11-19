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
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    final client = json['client'] is Map ? json['client'] as Map : const {};
    return ScheduleItem(
      id: '${json['id'] ?? ''}',
      type: (json['type'] as num?)?.toInt() ?? 0,
      title: (json['name'] ?? json['title'] ?? '').toString(),
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] ?? teacher['name'])?.toString(),
      clientId: ((json['clientId'] ?? client['id']) as num?)?.toInt(),
      clientName: (json['clientName'] ?? client['name'])?.toString(),
      startsAt: DateTime.tryParse('${json['startsAt'] ?? json['date'] ?? ''}'),
      endsAt: DateTime.tryParse('${json['endsAt'] ?? ''}'),
      isMine: json['isMine'] == true,
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
}
