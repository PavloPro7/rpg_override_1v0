import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/skill.dart';
import '../models/task.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Skill> _skills = [
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

  List<Task> _tasks = [];
  final _uuid = const Uuid();
  ThemeMode _themeMode = ThemeMode.system;

  AppState() {
    _loadFromFirestore();
  }

  List<Skill> get skills => _skills;
  List<Task> get tasks => _tasks;
  ThemeMode get themeMode => _themeMode;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  List<Task> get todayTasks => _tasks.where((t) {
    final now = DateTime.now();
    return t.date.year == now.year &&
        t.date.month == now.month &&
        t.date.day == now.day;
  }).toList();

  Future<void> _loadFromFirestore() async {
    // Load skills
    final skillsSnapshot = await _firestore.collection('skills').get();
    if (skillsSnapshot.docs.isNotEmpty) {
      _skills = skillsSnapshot.docs
          .map((doc) => Skill.fromMap(doc.data()))
          .toList();
    } else {
      // If no skills in Firestore, save initial skills
      for (var skill in _skills) {
        await _firestore.collection('skills').doc(skill.id).set(skill.toMap());
      }
    }

    // Load tasks
    final tasksSnapshot = await _firestore.collection('tasks').get();
    _tasks = tasksSnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();

    notifyListeners();
  }

  Future<void> addTask(String title, String skillId) async {
    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      skillId: skillId,
      date: DateTime.now(),
    );
    _tasks.add(newTask);
    notifyListeners();

    await _firestore.collection('tasks').doc(newTask.id).set(newTask.toMap());
  }

  Future<void> completeTask(String taskId) async {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && !_tasks[taskIndex].isCompleted) {
      _tasks[taskIndex].isCompleted = true;

      final skillIndex = _skills.indexWhere(
        (s) => s.id == _tasks[taskIndex].skillId,
      );

      if (skillIndex != -1) {
        _skills[skillIndex].addXp(1.0);

        // Update task in Firestore
        await _firestore.collection('tasks').doc(taskId).update({
          'isCompleted': true,
        });

        // Update skill in Firestore
        await _firestore
            .collection('skills')
            .doc(_skills[skillIndex].id)
            .update({'xp': _skills[skillIndex].xp});
      }

      notifyListeners();
    }
  }

  Future<void> applyDailyPenalty() async {
    for (var skill in _skills) {
      skill.applyDailyPenalty(0.1);
      await _firestore.collection('skills').doc(skill.id).update({
        'xp': skill.xp,
      });
    }
    notifyListeners();
  }
}
