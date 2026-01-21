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
}