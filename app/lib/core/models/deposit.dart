class Deposit {
  const Deposit({
    required this.id,
    this.title,
    this.amount,
    this.createdAt,
    this.status,
  });

  factory Deposit.fromJson(Map<String, dynamic> json) {
    return Deposit(
      id: '${json['id'] ?? ''}',
      title: (json['name'] ?? json['title'])?.toString(),
      amount: (json['amount'] ?? json['sum']) as num?,
      createdAt: DateTime.tryParse('${json['created'] ?? json['createdAt'] ?? ''}'),
      status: json['status']?.toString(),
    );
  }

  final String id;
  final String? title;
  final num? amount;
  final DateTime? createdAt;
  final String? status;
}
