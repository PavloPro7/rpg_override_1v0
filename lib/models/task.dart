class Task {
  final String id;
  final String title;
  final String skillId;
  final DateTime date;
  bool isCompleted;
  bool isStarred;

  Task({
    required this.id,
    required this.title,
    required this.skillId,
    required this.date,
    this.isCompleted = false,
    this.isStarred = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'skillId': skillId,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'isStarred': isStarred,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      skillId: map['skillId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      isCompleted: map['isCompleted'] ?? false,
      isStarred: map['isStarred'] ?? false,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? skillId,
    DateTime? date,
    bool? isCompleted,
    bool? isStarred,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      skillId: skillId ?? this.skillId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isStarred: isStarred ?? this.isStarred,
    );
  }
}
