import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/skill.dart';
import '../models/task.dart';

class AppState extends ChangeNotifier {
  final List<Skill> _skills = [
    Skill(
      id: 'strength',
      name: 'Strength',
      category: 'Fitness',
      color: Colors.orangeAccent,
    ),
    Skill(
      id: 'programming',
      name: 'Programming',
      category: 'Development',
      color: Colors.greenAccent,
    ),
    Skill(
      id: 'ausbildung',
      name: 'Ausbildung',
      category: 'Career',
      color: Colors.redAccent,
    ),
    Skill(
      id: 'deutsch',
      name: 'Deutsch',
      category: 'Language',
      color: Colors.blueAccent,
    ),
    Skill(
      id: 'english',
      name: 'English',
      category: 'Language',
      color: Colors.blueAccent,
    ),
  ];

  final List<Task> _tasks = [];
  final _uuid = const Uuid();

  List<Skill> get skills => _skills;
  List<Task> get tasks => _tasks;
  List<Task> get todayTasks => _tasks.where((t) {
    final now = DateTime.now();
    return t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day;
  }).toList();

  void addTask(String title, String skillId) {
    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      skillId: skillId,
      date: DateTime.now(),
    );
    _tasks.add(newTask);
    notifyListeners();
  }
  void completeTask(String taskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && !_tasks[taskIndex].isCompleted) {
      _tasks[taskIndex].isCompleted = true;

      final skill = _skills.firstWhere(
        (s) => s.id == _tasks[taskIndex].skillId,
      );
      skill.addXp(1.0);
      notifyListeners();
    }
  }

  void applyDailyPenalty() {
    for (var skill in _skills) {
      skill.applyDailyPenalty(0.1);
    }
    notifyListeners();
  }
}