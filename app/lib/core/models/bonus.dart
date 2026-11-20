class Bonus {
  const Bonus({
    required this.id,
    this.type,
    this.typeText,
    this.sum,
    this.sumWithSign,
    this.createdAt,
    this.description,
    this.annotation,
    this.clientBonus,
    this.branchName,
  });

  factory Bonus.fromJson(Map<String, dynamic> json) {
    final branch = json['branch'] is Map ? json['branch'] as Map : const {};
    return Bonus(
      id: '${json['id'] ?? ''}',
      type: _int(json['type']),
      typeText: json['typeText']?.toString(),
      sum: _int(json['sum']),
      sumWithSign: _int(json['sumWithSign']),
      createdAt: _date(json['created'] ?? json['date']),
      description: json['descriptionTypeText']?.toString(),
      annotation: json['annotation']?.toString(),
      clientBonus: _int(json['clientBonus']),
      branchName: (json['branchName'] ?? branch['name'])?.toString(),
    );
  }

  final String id;
  final int? type;
  final String? typeText;
  final int? sum;
  final int? sumWithSign;
  final DateTime? createdAt;
  final String? description;
  final String? annotation;
  final int? clientBonus;
  final String? branchName;

  /// Positive for accrual, negative for spending, as returned by the vendor.
  int get signedAmount {
    final signed = sumWithSign;
    if (signed != null) return signed;
    final value = sum ?? 0;
    return type == 2 ? -value : value;
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
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
