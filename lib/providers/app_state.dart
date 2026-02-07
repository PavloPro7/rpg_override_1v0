import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/skill.dart';
import '../models/task.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;

  List<Skill> _skills = [];
  List<Task> _tasks = [];
  final _uuid = const Uuid();
  ThemeMode _themeMode = ThemeMode.system;

  AppState() {
    _skills = _initialSkills();
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _loadFromFirestore();
      } else {
        _skills = _initialSkills();
        _tasks = [];
        notifyListeners();
      }
    });
  }

  List<Skill> _initialSkills() => [
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

  List<Skill> get skills => _skills;
  List<Task> get tasks => _tasks;
  ThemeMode get themeMode => _themeMode;
  User? get currentUser => _user;
  bool get isAuthenticated => _user != null;

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();
  }

  // Auth Methods
  Future<String?> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _loadFromFirestore() async {
    if (_user == null) return;

    final userDoc = _firestore.collection('users').doc(_user!.uid);

    // Load skills
    final skillsSnapshot = await userDoc.collection('skills').get();
    if (skillsSnapshot.docs.isNotEmpty) {
      _skills = skillsSnapshot.docs
          .map((doc) => Skill.fromMap(doc.data()))
          .toList();
    } else {
      for (var skill in _initialSkills()) {
        await userDoc.collection('skills').doc(skill.id).set(skill.toMap());
      }
      _skills = _initialSkills();
    }

    // Load tasks
    final tasksSnapshot = await userDoc.collection('tasks').get();
    _tasks = tasksSnapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();

    notifyListeners();
  }

  Future<void> addTask(String title, String skillId, {DateTime? date}) async {
    if (_user == null) return;
    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      skillId: skillId,
      date: date ?? DateTime.now(),
    );
    _tasks.add(newTask);
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks')
        .doc(newTask.id)
        .set(newTask.toMap());
  }

  Future<void> updateTaskDate(String taskId, DateTime newDate) async {
    if (_user == null) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(date: newDate);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'date': newDate.toIso8601String()});
    }
  }

  Future<void> addSkill(
    String name,
    String category,
    Color color,
    double difficulty,
    int startLevel,
    String icon,
  ) async {
    if (_user == null) return;
    final newSkill = Skill(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      category: category,
      color: color,
      difficulty: difficulty,
      xp: (startLevel - 1) * (100 * difficulty),
      icon: icon,
    );

    _skills.add(newSkill);
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('skills')
        .doc(newSkill.id)
        .set(newSkill.toMap());
  }

  Future<void> updateSkill(Skill skill) async {
    if (_user == null) return;
    final index = _skills.indexWhere((s) => s.id == skill.id);
    if (index != -1) {
      _skills[index] = skill;
      notifyListeners();
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('skills')
          .doc(skill.id)
          .update(skill.toMap());
    }
  }

  Future<void> removeSkill(String skillId) async {
    if (_user == null) return;
    _skills.removeWhere((s) => s.id == skillId);
    notifyListeners();
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('skills')
        .doc(skillId)
        .delete();
  }

  Future<void> completeTask(String taskId) async {
    if (_user == null) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1 && !_tasks[taskIndex].isCompleted) {
      _tasks[taskIndex].isCompleted = true;

      final skillIndex = _skills.indexWhere(
        (s) => s.id == _tasks[taskIndex].skillId,
      );

      if (skillIndex != -1) {
        _skills[skillIndex].addXp(10.0);

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('tasks')
            .doc(taskId)
            .update({'isCompleted': true});

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('skills')
            .doc(_skills[skillIndex].id)
            .update({'xp': _skills[skillIndex].xp});
      }
      notifyListeners();
    }
  }

  Future<void> applyDailyPenalty() async {
    if (_user == null) return;
    for (var skill in _skills) {
      skill.applyDailyPenalty(0.1);
      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('skills')
          .doc(skill.id)
          .update({'xp': skill.xp});
    }
    notifyListeners();
  }
}
