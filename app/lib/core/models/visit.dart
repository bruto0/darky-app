class Visit {
  const Visit({
    required this.id,
    this.title,
    this.hallName,
    this.teacherName,
    this.visitedAt,
    this.status,
  });

  factory Visit.fromJson(Map<String, dynamic> json) {
    final hall = json['hall'] is Map ? json['hall'] as Map : const {};
    final teacher = json['teacher'] is Map ? json['teacher'] as Map : const {};
    return Visit(
      id: '${json['id'] ?? ''}',
      title: (json['name'] ?? json['title'])?.toString(),
      hallName: (json['hallName'] ?? hall['name'])?.toString(),
      teacherName: (json['teacherName'] ?? teacher['name'])?.toString(),
      visitedAt: DateTime.tryParse('${json['visit_date'] ?? json['visitedAt'] ?? ''}'),
      status: json['status']?.toString(),
    );
  }

  final String id;
  final String? title;
  final String? hallName;
  final String? teacherName;
  final DateTime? visitedAt;
  final String? status;
}
