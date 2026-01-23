class Task {
  final String id;
  final String title;
  final String skillId;
  final DateTime date;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.skillId,
    required this.date,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'skillId': skillId,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      skillId: map['skillId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isCompleted: map['isCompleted'] ?? false,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? skillId,
    DateTime? date,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      skillId: skillId ?? this.skillId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
