class AccountPacket {
  const AccountPacket({
    required this.value,
    required this.days,
    this.minimumDays,
  });

  factory AccountPacket.fromJson(Map<String, dynamic> json) {
    return AccountPacket(
      value: (json['value'] as num?)?.toInt() ?? 0,
      days: (json['days'] as num?)?.toInt() ?? 0,
      minimumDays: int.tryParse('${json['min'] ?? ''}'),
    );
  }

  final int value;
  final int days;
  final int? minimumDays;
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
    this.packets = const [],
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    final visits = json['visits'] is Map ? json['visits'] as Map : const {};
    final freezes = json['freezes'] is Map ? json['freezes'] as Map : const {};
    final type = json['type'] is Map ? json['type'] as Map : const {};
    final status = json['status'] is Map ? json['status'] as Map : const {};
    final packets = json['packets'] is List ? json['packets'] as List : const [];

    return Account(
      id: (json['id'] as num?)?.toInt() ?? 0,
      typeName: (json['typeName'] ?? type['name'] ?? '').toString(),
      statusName: (json['statusName'] ?? status['name'])?.toString(),
      visitsLeft:
          ((json['visitsLeft'] ?? visits['left']) as num?)?.toInt() ?? 0,
      visitsTotal:
          ((json['visitsTotal'] ?? visits['total']) as num?)?.toInt() ?? 0,
      freezeDaysLeft:
          ((json['freezeDaysLeft'] ?? freezes['left']) as num?)?.toInt() ?? 0,
      freezeDaysTotal:
          ((json['freezeDaysTotal'] ?? freezes['total']) as num?)?.toInt() ?? 0,
      freezeEnable: json['freezeEnable'] == true,
      closed: json['closed'] == true,
      freeze: json['freeze'] == true,
      validUntil: DateTime.tryParse('${json['validUntil'] ?? ''}'),
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
  final List<AccountPacket> packets;

  /// Freeze is available only for an active, non-closed, non-frozen account
  /// with at least one freeze day left and an explicit freeze flag.
  bool get freezeAvailable =>
      freezeEnable && !closed && !freeze && freezeDaysLeft > 0;

  bool get isActive => !closed;
}
