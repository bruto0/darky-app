class AccountPacket {
  const AccountPacket({
    required this.value,
    required this.days,
    this.minimumDays,
    this.count,
    this.used,
    this.typeName,
  });

  factory AccountPacket.fromJson(Map<String, dynamic> json) {
    return AccountPacket(
      value: (json['value'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 0,
      minimumDays: int.tryParse('${json['min'] ?? ''}'),
      count: (json['count'] as num?)?.toInt(),
      used: (json['used'] as num?)?.toInt(),
      typeName: (json['type']?['name'] ?? json['typeName'])?.toString(),
    );
  }

  final int value;
  final int days;
  final int? minimumDays;
  final int? count;
  final int? used;
  final String? typeName;
}

class Account {
  const Account({
    required this.id,
    required this.typeName,
    required this.visitsLeft,
    required this.visitsTotal,
    required this.freezeDaysLeft,
    required this.freezeDaysTotal,
    required this.freezeEnable,
    required this.closed,
    required this.freeze,
    this.statusName,
    this.validUntil,
    this.entity,
    this.active = true,
    this.typeColor,
    this.freezeDays,
    this.trainings = 0,
    this.trainingsUsed = 0,
    this.packets = const [],
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final visits = json['visits'] is Map ? json['visits'] as Map : const {};
    final freezes = json['freezes'] is Map ? json['freezes'] as Map : const {};
    final type = json['type'] is Map ? json['type'] as Map : const {};
    final status = json['status'] is Map ? json['status'] as Map : const {};
    final packets = json['packets'] is List ? json['packets'] as List : const [];
    final trainings = (json['trainings'] as num?)?.toInt() ?? 0;
    final trainingsUsed = (json['trainingsUsed'] as num?)?.toInt() ?? 0;

    return Account(
      id: (json['id'] as num?)?.toInt() ?? 0,
      typeName: (json['typeName'] ?? type['name'] ?? '').toString(),
      statusName: (json['statusName'] ?? status['name'])?.toString(),
      visitsLeft:
          ((json['visitsLeft'] ?? json['trainingsLeft'] ?? visits['left']) as num?)
                  ?.toInt() ??
              (trainings - trainingsUsed).clamp(0, 1 << 30),
      visitsTotal:
          ((json['visitsTotal'] ?? visits['total']) as num?)?.toInt() ??
              trainings,
      freezeDaysLeft:
          ((json['freezeDaysLeft'] ?? freezes['left']) as num?)?.toInt() ?? 0,
      freezeDaysTotal:
          ((json['freezeDaysTotal'] ?? freezes['total']) as num?)?.toInt() ?? 0,
      freezeEnable: json['freezeEnable'] == true,
      closed: json['closed'] == true,
      freeze: json['freeze'] == true,
      validUntil: _date(json['validUntil'] ?? json['endDate']),
      entity: json['entity']?.toString(),
      active: json['active'] != false,
      typeColor: json['typeColor']?.toString(),
      freezeDays: (json['freezeDays'] as num?)?.toInt(),
      trainings: trainings,
      trainingsUsed: trainingsUsed,
      packets: [
        for (final packet in packets)
          if (packet is Map)
            AccountPacket.fromJson(Map<String, dynamic>.from(packet)),
      ],
    );
  }

  final int id;
  final String typeName;
  final String? statusName;
  final int visitsLeft;
  final int visitsTotal;
  final int freezeDaysLeft;
  final int freezeDaysTotal;
  final bool freezeEnable;
  final bool closed;
  final bool freeze;
  final DateTime? validUntil;
  final String? entity;
  final bool active;
  final String? typeColor;
  final int? freezeDays;
  final int trainings;
  final int trainingsUsed;
  final List<AccountPacket> packets;

  bool get freezeAvailable =>
      freezeEnable &&
      active &&
      !closed &&
      !freeze &&
      freezeDaysLeft > 0;

  bool get isActive => active && !closed;

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
