class Task {
  final String id;
  final String title;
  final String skillId;
  final DateTime date;
  bool isCompleted;
  bool isStarred;
  bool isPinned;
  List<String> completedDates;

  Task({
    required this.id,
    required this.title,
    required this.skillId,
    required this.date,
    this.isCompleted = false,
    this.isStarred = false,
    this.isPinned = false,
    this.completedDates = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'skillId': skillId,
      'date': date.toIso8601String(),
      'isCompleted': isCompleted,
      'isStarred': isStarred,
      'isPinned': isPinned,
      'completedDates': completedDates,
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
      isPinned: map['isPinned'] ?? false,
      completedDates: List<String>.from(map['completedDates'] ?? []),
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? skillId,
    DateTime? date,
    bool? isCompleted,
    bool? isStarred,
    bool? isPinned,
    List<String>? completedDates,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      skillId: skillId ?? this.skillId,
      date: date ?? this.date,
      isCompleted: isCompleted ?? this.isCompleted,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      completedDates: completedDates ?? this.completedDates,
    );
  }
}
