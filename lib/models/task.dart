class Task {
  final String id;
  final String title;
  final String skillId;
  final DateTime date;
  final DateTime? time; // Optional time
  bool isCompleted;
  bool isStarred;
  bool isPinned;
  List<String> completedDates;
  final int difficulty;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    required this.skillId,
    required this.date,
    this.time,
    this.isCompleted = false,
    this.isStarred = false,
    this.isPinned = false,
    this.completedDates = const [],
    this.difficulty = 1,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'skillId': skillId,
      'date': date.toIso8601String(),
      'time': time?.toIso8601String(),
      'isCompleted': isCompleted,
      'isStarred': isStarred,
      'isPinned': isPinned,
      'completedDates': completedDates,
      'difficulty': difficulty,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      skillId: map['skillId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      time: map['time'] != null ? DateTime.parse(map['time']) : null,
      isCompleted: map['isCompleted'] ?? false,
      isStarred: map['isStarred'] ?? false,
      isPinned: map['isPinned'] ?? false,
      completedDates: List<String>.from(map['completedDates'] ?? []),
      difficulty: map['difficulty'] ?? 1,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Task copyWith({
    String? id,
    String? title,
    String? skillId,
    DateTime? date,
    DateTime? time,
    bool? isCompleted,
    bool? isStarred,
    bool? isPinned,
    List<String>? completedDates,
    int? difficulty,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      skillId: skillId ?? this.skillId,
      date: date ?? this.date,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      isStarred: isStarred ?? this.isStarred,
      isPinned: isPinned ?? this.isPinned,
      completedDates: completedDates ?? this.completedDates,
      difficulty: difficulty ?? this.difficulty,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
