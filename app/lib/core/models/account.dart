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
      value: Account._int(json['value']) ?? 0,
      days: Account._int(json['days']) ?? 0,
      minimumDays: int.tryParse('${json['min'] ?? ''}'),
      count: Account._int(json['count']),
      used: Account._int(json['used']),
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
    final trainings = _int(json['trainings']) ?? 0;
    final trainingsUsed = _int(json['trainingsUsed']) ?? 0;
    final freezeDays = _int(json['freezeDays']);
    final packetFreezeDays = packets
        .whereType<Map>()
        .map((packet) => _int(packet['days']) ?? 0)
        .fold<int>(0, (max, days) => days > max ? days : max);
    final freezeDaysTotal = _int(json['freezeDaysTotal']) ??
        freezeDays ??
        (_int(freezes['total']) ?? packetFreezeDays);
    final freezeDaysLeft =
        _int(json['freezeDaysLeft']) ?? (_int(freezes['left']) ?? freezeDaysTotal);

    return Account(
      id: _int(json['id']) ?? 0,
      typeName: (json['typeName'] ?? type['name'] ?? '').toString(),
      statusName: (json['statusName'] ?? status['name'])?.toString(),
      visitsLeft:
          (_int(json['visitsLeft']) ??
                  _int(json['trainingsLeft']) ??
                  _int(visits['left'])) ??
              (trainings - trainingsUsed).clamp(0, 1 << 30),
      visitsTotal:
          (_int(json['visitsTotal']) ?? _int(visits['total'])) ?? trainings,
      freezeDaysLeft: freezeDaysLeft,
      freezeDaysTotal: freezeDaysTotal,
      freezeEnable: json['freezeEnable'] == null
          ? freezeDaysTotal > 0
          : _bool(json['freezeEnable']),
      closed: _bool(json['closed']),
      freeze: _bool(json['freeze']),
      validUntil: _date(json['validUntil'] ?? json['endDate']),
      entity: json['entity']?.toString(),
      active: json['active'] == null ? true : _bool(json['active']),
      typeColor: json['typeColor']?.toString(),
      freezeDays: freezeDays,
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
      active &&
      !closed &&
      !freeze &&
      freezeDaysLeft > 0 &&
      (freezeEnable || packets.any((packet) => packet.days > 0));

  bool get isActive => active && !closed;

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static bool _bool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
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

