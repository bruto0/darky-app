class Booking {
  const Booking({
    required this.id,
    this.title,
    this.hallName,
    this.teacherName,
    this.startsAt,
    this.status,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    return Booking(
      id: '${json['id'] ?? ''}',
      title: (json['name'] ?? json['title'])?.toString(),
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] ?? teacher['name'])?.toString(),
      startsAt: DateTime.tryParse('${json['startsAt'] ?? json['date'] ?? ''}'),
      status: json['status']?.toString(),
    );
  }

  final String id;
  final String? title;
  final String? hallName;
  final String? teacherName;
  final DateTime? startsAt;
  final String? status;
}
