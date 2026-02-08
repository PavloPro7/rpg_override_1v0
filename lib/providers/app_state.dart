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
  String? _userName;
  int? _userAge;
  String? _avatarUrl;
  DateTime? _registrationDateFromFirestore;
  bool _isSigningUp = false;
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
        _userName = null;
        _userAge = null;
        _avatarUrl = null;
        _themeMode = ThemeMode.system;
        notifyListeners();
      }
    });
  }

  List<Skill> _initialSkills() => [
    Skill(
      id: 'english',
      name: 'English',
      category: 'Language',
      color: Colors.blueAccent,
      icon: '🇺🇸',
      difficulty: 4.0,
      xp: 1200.0, // (Level 4 - 1) * (100 * Difficulty 4)
    ),
    Skill(
      id: 'education',
      name: 'Education',
      category: 'Career',
      color: Colors.redAccent,
      icon: '🎒',
      difficulty: 4.0,
      xp: 1200.0,
    ),
    Skill(
      id: 'strength',
      name: 'Strengh',
      category: 'Fitness',
      color: Colors.orangeAccent,
      icon: '💪',
      difficulty: 4.0,
      xp: 1200.0,
    ),
    Skill(
      id: 'german',
      name: 'German',
      category: 'Language',
      color: Colors.blueAccent,
      icon: '🇩🇪',
      difficulty: 4.0,
      xp: 1200.0,
    ),
  ];

  List<Skill> get skills => _skills;
  List<Task> get tasks => _tasks;
  ThemeMode get themeMode => _themeMode;
  User? get currentUser => _user;
  String? get userName => _userName;
  int? get userAge => _userAge;
  String? get avatarUrl => _avatarUrl;
  DateTime? get registrationDate {
    if (_registrationDateFromFirestore != null) {
      return _registrationDateFromFirestore!.toUtc();
    }
    return _user?.metadata.creationTime?.toUtc();
  }

  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isAnonymous => _user?.isAnonymous ?? false;

  Future<void> reloadUser() async {
    await _user?.reload();
    _user = _auth.currentUser;
    notifyListeners();
  }

  Future<String?> sendEmailVerification() async {
    try {
      await _user?.sendEmailVerification();
      debugPrint('Verification email sent to: ${_user?.email}');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('Error sending verification email: ${e.message}');
      return e.message;
    }
  }

  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    debugPrint('Theme toggled to: ${_themeMode.name}');
    notifyListeners();

    if (_user != null) {
      _firestore
          .collection('users')
          .doc(_user!.uid)
          .set({'themeMode': _themeMode.name}, SetOptions(merge: true))
          .then((_) {
            debugPrint('Theme saved to Firestore: ${_themeMode.name}');
          })
          .catchError((e) {
            debugPrint('Failed to save theme to Firestore: $e');
          });
    }
  }

  List<Task> getTasksForDate(DateTime date) {
    return _tasks.where((t) {
      return t.date.year == date.year &&
          t.date.month == date.month &&
          t.date.day == date.day;
    }).toList();
  }

  // Auth Methods
  Future<String?> signUp(
    String email,
    String password,
    String name,
    int age,
    String? avatarUrl,
  ) async {
    _isSigningUp = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
        await credential.user!.updateDisplayName(name);
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': name,
          'age': age,
          'avatarUrl': avatarUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _userName = name;
        _userAge = age;
        _avatarUrl = avatarUrl;
        notifyListeners();
      }
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _isSigningUp = false;
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

  Future<String?> signInAnonymously() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateProfile(String name, int age, String? avatarUrl) async {
    if (_user == null) return "No user logged in";
    try {
      await _firestore.collection('users').doc(_user!.uid).set({
        'name': name,
        'age': age,
        'avatarUrl': avatarUrl,
      }, SetOptions(merge: true));
      _userName = name;
      _userAge = age;
      _avatarUrl = avatarUrl;
      await _user!.updateDisplayName(name);
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updateEmail(String newEmail) async {
    if (_user == null) return "No user logged in";
    try {
      // Modern secure way: sends verification to new email before updating
      await _user!.verifyBeforeUpdateEmail(newEmail);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "Security check failed. Please log out and log in again to change your email.";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> updatePassword(String newPassword) async {
    if (_user == null) return "No user logged in";
    try {
      await _user!.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return "Security check failed. Please log out and log in again to change your password.";
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> _loadFromFirestore() async {
    if (_user == null || _isSigningUp) return;

    final userDoc = _firestore.collection('users').doc(_user!.uid);

    // Load user profile
    final userSnapshot = await userDoc.get();
    if (userSnapshot.exists) {
      final userData = userSnapshot.data();
      debugPrint('DEBUG: Loading profile for ${_user!.email}: $userData');
      _userName = (userData?['name'] as String?) ?? _user?.displayName;
      _userAge = userData?['age'] as int?;
      _avatarUrl = userData?['avatarUrl'] as String?;
      debugPrint('DEBUG: Profile Sync - Name: $_userName, Age: $_userAge');

      final createdAtVal = userData?['createdAt'];
      if (createdAtVal is Timestamp) {
        _registrationDateFromFirestore = createdAtVal.toDate();
      } else if (createdAtVal is String) {
        _registrationDateFromFirestore = DateTime.tryParse(createdAtVal);
      }
      final savedTheme = userData?['themeMode'] as String?;
      debugPrint('Loaded theme from Firestore: $savedTheme');
      if (savedTheme != null) {
        try {
          _themeMode = ThemeMode.values.firstWhere(
            (m) => m.name == savedTheme,
            orElse: () => ThemeMode.system,
          );
          debugPrint('Applied theme mode: ${_themeMode.name}');
          notifyListeners(); // Update theme immediately
        } catch (e) {
          debugPrint('Error parsing saved theme: $e');
        }
      }
    }

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
