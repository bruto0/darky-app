class Deposit {
  const Deposit({
    required this.id,
    this.title,
    this.amount,
    this.createdAt,
    this.status,
    this.typeText,
    this.sum,
    this.sumWithSign,
    this.paymentText,
    this.targetNumber,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    final target = json['target'] is Map ? json['target'] as Map : const {};
    final sum = _num(json['sum']);
    return Deposit(
      id: '${json['id'] ?? ''}',
      title: (json['name'] ?? json['title'] ?? json['typeText'])?.toString(),
      amount: _num(json['amount'] ?? sum),
      createdAt: _date(json['created'] ?? json['createdAt']),
      status: json['status']?.toString(),
      typeText: json['typeText']?.toString(),
      sum: sum,
      sumWithSign: json['sumWithSign']?.toString(),
      paymentText: json['paymentText']?.toString(),
      targetNumber: _int(json['targetNumber']) ?? _int(target['number']),
    );
  }

  final String id;
  final String? title;
  final num? amount;
  final DateTime? createdAt;
  final String? status;
  final String? typeText;
  final num? sum;
  final String? sumWithSign;
  final String? paymentText;
  final int? targetNumber;

  bool get isIncome => (sum ?? amount ?? 0) >= 0;

  static num? _num(Object? value) {
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
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
