import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/skill.dart';
import '../models/task.dart';

class AppState extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
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
  bool _staySignedIn = true;
  String? _defaultSkillId;

  bool _isProfileLoaded = false;

  AppState() {
    _loadPreferences();
    _skills = _initialSkills();
    _auth.authStateChanges().listen((user) {
      _user = user;
      if (user != null) {
        _isProfileLoaded = false;
        _loadFromFirestore();
      } else {
        _isProfileLoaded = false;
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

  List<Skill> _initialSkills() => [];

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

  bool get staySignedIn => _staySignedIn;

  void setStaySignedIn(bool value) {
    _staySignedIn = value;
    notifyListeners();
    _savePreferences();
  }

  String? get defaultSkillId => _defaultSkillId;

  void setDefaultSkillId(String? skillId) {
    _defaultSkillId = skillId;
    notifyListeners();
    _savePreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _staySignedIn = prefs.getBool('staySignedIn') ?? true;
    _defaultSkillId = prefs.getString('defaultSkillId');
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('staySignedIn', _staySignedIn);
    if (_defaultSkillId != null) {
      await prefs.setString('defaultSkillId', _defaultSkillId!);
    } else {
      await prefs.remove('defaultSkillId');
    }
  }

  bool get isAuthenticated => _user != null;
  bool get isEmailVerified => _user?.emailVerified ?? false;
  bool get isAnonymous => _user?.isAnonymous ?? false;
  bool get isProfileLoaded => _isProfileLoaded;
  bool get isOnboarded => (_userName != null && _userName!.isNotEmpty && _userName != 'Hero') && (_userAge != null && _userAge! > 0);

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
      if (t.isPinned) {
        final endDate = t.pinnedUntil ?? t.date.add(const Duration(days: 35));
        return !date.isBefore(t.date) && !date.isAfter(endDate);
      }
      // Ended pinned tasks (pinnedUntil set, isPinned false): show from original date to pinnedUntil
      if (t.pinnedUntil != null && !t.isPinned) {
        return !date.isBefore(t.date) && !date.isAfter(t.pinnedUntil!);
      }
      return DateUtils.isSameDay(t.date, date);
    }).toList();
  }

  // Auth Methods
  Future<String?> signUp(
    String email,
    String password,
  ) async {
    debugPrint('[AppState] signUp: email=$email');
    _isSigningUp = true;
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await credential.user!.sendEmailVerification();
        await credential.user!.updateDisplayName('Hero');
        await _firestore.collection('users').doc(credential.user!.uid).set({
          'name': 'Hero',
          'age': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _userName = 'Hero';
        _userAge = 0;
        _isProfileLoaded = true;
        notifyListeners();
      }
      await _savePreferences();
      // Finalize autofill context
      TextInput.finishAutofillContext();
      debugPrint('[AppState] signUp: success email=$email');
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AppState] signUp: error=${e.message}');
      return e.message;
    } finally {
      _isSigningUp = false;
    }
  }

  Future<String?> signIn(String email, String password) async {
    debugPrint('[AppState] signIn: email=$email');
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _savePreferences();
      // Finalize autofill context
      TextInput.finishAutofillContext();
      debugPrint('[AppState] signIn: success email=$email');
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential' || e.code == 'wrong-password' || e.code == 'user-not-found') {
        debugPrint('[AppState] signIn: error=invalid-credential');
        return 'Password or email incorrect';
      }
      debugPrint('[AppState] signIn: error=${e.message}');
      return e.message;
    }
  }

  Future<String?> signInWithGoogle() async {
    debugPrint('[AppState] signInWithGoogle: started');
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint('[AppState] signInWithGoogle: cancelled');
        return null; // Cancelled
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // If it's a new user, initialize profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        debugPrint('[AppState] signInWithGoogle: new user uid=${userCredential.user?.uid}');
        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Hero',
            'age': 0,
            'avatarUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        debugPrint('[AppState] signInWithGoogle: existing user uid=${userCredential.user?.uid}');
      }

      await _savePreferences();
      // Finalize autofill context
      TextInput.finishAutofillContext();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AppState] signInWithGoogle: error=${e.message}');
      return e.message;
    } catch (e) {
      debugPrint('[AppState] signInWithGoogle: error=$e');
      return e.toString();
    }
  }

  Future<String?> signInWithApple() async {
    debugPrint('[AppState] signInWithApple: started');
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthProvider oAuthProvider = OAuthProvider('apple.com');
      final AuthCredential credential = oAuthProvider.credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // If it's a new user, initialize profile
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        debugPrint('[AppState] signInWithApple: new user uid=${userCredential.user?.uid}');
        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'Hero',
            'age': 0,
            'avatarUrl': user.photoURL,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } else {
        debugPrint('[AppState] signInWithApple: existing user uid=${userCredential.user?.uid}');
      }

      await _savePreferences();
      TextInput.finishAutofillContext();
      return null;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AppState] signInWithApple: error=${e.message}');
      return e.message;
    } catch (e) {
      if (e is SignInWithAppleAuthorizationException &&
          e.code == AuthorizationErrorCode.canceled) {
        debugPrint('[AppState] signInWithApple: cancelled');
        return null; // Cancelled
      }
      debugPrint('[AppState] signInWithApple: error=$e');
      return e.toString();
    }
  }

  // Account Management Methods

  Future<void> resetAccount() async {
    if (_user == null) return;
    debugPrint('[AppState] resetAccount: uid=${_user!.uid}');
    try {
      final userDoc = _firestore.collection('users').doc(_user!.uid);
      
      // Delete tasks collection
      final tasks = await userDoc.collection('tasks').get();
      for (final doc in tasks.docs) {
        await doc.reference.delete();
      }
      
      // Update user doc back to pre-onboarding defaults
      await userDoc.set({
        'name': 'Hero',
        'age': 0,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _userName = 'Hero';
      _userAge = 0;
      _tasks = [];
      _skills = _initialSkills();
      await _savePreferences();
      notifyListeners();
    } catch (e) {
      debugPrint('Error resetting account: $e');
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    if (_user == null) return;
    debugPrint('[AppState] deleteAccount: uid=${_user!.uid}');
    try {
      final userDoc = _firestore.collection('users').doc(_user!.uid);
      
      // Delete tasks collection
      final tasks = await userDoc.collection('tasks').get();
      for (final doc in tasks.docs) {
        await doc.reference.delete();
      }
      
      // Delete user document
      await userDoc.delete();
      
      // Attempt auth account deletion
      final currentUser = _user; // save ref before signOut clears it
      await signOut(); // This clears local state
      
      // Firebase auth deletion requires recent authentication. 
      // This may throw a 'requires-recent-login' exception if the session is too old.
      await currentUser?.delete(); 
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
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

  Future<String?> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  Future<String?> updateProfile(String name, int age, String? avatarUrl) async {
    if (_user == null) return "No user logged in";
    debugPrint('[AppState] updateProfile: name="$name" age=$age');
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
    final masked = newEmail.length > 3 ? '${newEmail.substring(0, 3)}***@${newEmail.split('@').last}' : '***';
    debugPrint('[AppState] updateEmail: newEmail=$masked');
    try {
      // Modern secure way: sends verification to new email before updating
      await _user!.verifyBeforeUpdateEmail(newEmail);
      debugPrint('[AppState] updateEmail: verification sent to $masked');
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
    debugPrint('[AppState] updatePassword: password update attempted');
    try {
      await _user!.updatePassword(newPassword);
      debugPrint('[AppState] updatePassword: success');
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
    debugPrint('[AppState] signOut: uid=${_user?.uid}');
    await _auth.signOut();
    debugPrint('[AppState] signOut: done');
  }

  Future<void> _loadFromFirestore() async {
    if (_user == null || _isSigningUp) return;
    debugPrint('[AppState] _loadFromFirestore: uid=${_user!.uid}');

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

    debugPrint('[AppState] _loadFromFirestore: loaded ${_skills.length} skills, ${_tasks.length} tasks');
    _isProfileLoaded = true;
    notifyListeners();
  }

  Future<void> addTask(
    String title,
    String skillId, {
    DateTime? date,
    DateTime? time,
    int difficulty = 1,
  }) async {
    if (_user == null) return;
    debugPrint('[AppState] addTask: title="$title" skillId=$skillId date=${date?.toIso8601String()} difficulty=$difficulty');
    final newTask = Task(
      id: _uuid.v4(),
      title: title,
      skillId: skillId,
      date: DateUtils.dateOnly(date ?? DateTime.now()),
      time: time,
      difficulty: difficulty,
      isStarred: false,
      isPinned: false,
      updatedAt: DateTime.now(),
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

  Future<void> updateTaskContent(
    String taskId,
    String title,
    String skillId, {
    DateTime? date,
    DateTime? time,
    bool clearTime = false,
    int? difficulty,
  }) async {
    if (_user == null) return;
    debugPrint('[AppState] updateTaskContent: taskId=$taskId title="$title" skillId=$skillId date=${date?.toIso8601String()}');
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final existingTask = _tasks[taskIndex];
    final updatedTask = Task(
      id: existingTask.id,
      title: title,
      skillId: skillId,
      date: date ?? existingTask.date,
      time: clearTime ? null : (time ?? existingTask.time),
      difficulty: difficulty ?? existingTask.difficulty,
      isCompleted: existingTask.isCompleted,
      isStarred: existingTask.isStarred,
      isPinned: existingTask.isPinned,
      completedDates: existingTask.completedDates,
      updatedAt: DateTime.now(),
    );

    _tasks[taskIndex] = updatedTask;
    notifyListeners();

    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks')
        .doc(taskId)
        .set(updatedTask.toMap());
  }

  Future<void> deleteTasks(List<String> taskIds) async {
    if (_user == null) return;
    debugPrint('[AppState] deleteTasks: ${taskIds.length} tasks ids=$taskIds');

    // Update local state
    _tasks.removeWhere((t) => taskIds.contains(t.id));
    notifyListeners();

    // Update Firestore in batch
    final batch = _firestore.batch();
    final userTasksRef = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks');

    for (final id in taskIds) {
      batch.delete(userTasksRef.doc(id));
    }
    await batch.commit();
  }

  Future<void> updateTaskDate(String taskId, DateTime newDate) async {
    if (_user == null) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final normalizedDate = DateUtils.dateOnly(newDate);
      debugPrint('[AppState] updateTaskDate: taskId=$taskId oldDate=${_tasks[taskIndex].date.toIso8601String()} → newDate=${normalizedDate.toIso8601String()}');
      final now = DateTime.now();
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(date: normalizedDate, updatedAt: now);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'date': normalizedDate.toIso8601String(), 'updatedAt': now.toIso8601String()});
    }
  }

  Future<void> addSkill(
    String name,
    Color color,
    int startLevel,
    String icon,
  ) async {
    if (_user == null) return;
    debugPrint('[AppState] addSkill: name="$name" startLevel=$startLevel icon=$icon');
    final newSkill = Skill(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      color: color,
      xp: (startLevel - 1) * 100.0,
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
    debugPrint('[AppState] updateSkill: skillId=${skill.id} name="${skill.name}"');
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
    debugPrint('[AppState] removeSkill: skillId=$skillId');
    _skills.removeWhere((s) => s.id == skillId);
    notifyListeners();
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('skills')
        .doc(skillId)
        .delete();
  }

  Future<void> completeTask(String taskId, {DateTime? onDate}) async {
    if (_user == null) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final date = onDate ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    debugPrint('[AppState] completeTask: taskId=$taskId onDate=$dateStr isPinned=${task.isPinned} skillId=${task.skillId}');

    final now = DateTime.now();

    // Skip XP logic for general tasks
    if (task.skillId == 'none') {
      if (task.isPinned) {
        final wasCompleted = task.completedDates.contains(dateStr);
        if (wasCompleted) {
          task.completedDates.remove(dateStr);
        } else {
          task.completedDates.add(dateStr);
        }
        debugPrint('[AppState] completeTask: general pinned → completed=${!wasCompleted} date=$dateStr');
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(updatedAt: now);
        notifyListeners();
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('tasks')
            .doc(taskId)
            .update({'completedDates': task.completedDates, 'updatedAt': now.toIso8601String()});
      } else {
        task.isCompleted = !task.isCompleted;
        debugPrint('[AppState] completeTask: general regular → completed=${task.isCompleted}');
        _tasks[taskIndex] = _tasks[taskIndex].copyWith(updatedAt: now);
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('tasks')
            .doc(taskId)
            .update({'isCompleted': task.isCompleted, 'updatedAt': now.toIso8601String()});
        notifyListeners();
      }
      return;
    }

    final skillIndex = _skills.indexWhere((s) => s.id == task.skillId);

    if (task.isPinned) {
      // Toggle completion for specific day
      final double xpAmount = 30.0 * (task.difficulty / 5.0);
      if (task.completedDates.contains(dateStr)) {
        task.completedDates.remove(dateStr);
        // Undo XP reward (Tripled: 10.0 * 3)
        if (skillIndex != -1) {
          _skills[skillIndex].addXp(-xpAmount);
        }
        debugPrint('[AppState] completeTask: skill pinned → uncompleted date=$dateStr xp=-$xpAmount');
      } else {
        task.completedDates.add(dateStr);
        // Add XP reward (Tripled: 10.0 * 3)
        if (skillIndex != -1) {
          _skills[skillIndex].addXp(xpAmount);
        }
        debugPrint('[AppState] completeTask: skill pinned → completed date=$dateStr xp=+$xpAmount');
      }

      _tasks[taskIndex] = _tasks[taskIndex].copyWith(updatedAt: now);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'completedDates': task.completedDates, 'updatedAt': now.toIso8601String()});

      if (skillIndex != -1) {
        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('skills')
            .doc(_skills[skillIndex].id)
            .update({'xp': _skills[skillIndex].xp});
      }
    } else {
      // Toggle regular task completion
      task.isCompleted = !task.isCompleted;

      if (skillIndex != -1) {
        final double xpAmount = 30.0 * (task.difficulty / 5.0);
        if (task.isCompleted) {
          _skills[skillIndex].addXp(xpAmount); // Tripled XP * multiplier
          debugPrint('[AppState] completeTask: skill regular → completed xp=+$xpAmount');
        } else {
          _skills[skillIndex].addXp(-xpAmount); // Tripled XP * multiplier
          debugPrint('[AppState] completeTask: skill regular → uncompleted xp=-$xpAmount');
        }

        await _firestore
            .collection('users')
            .doc(_user!.uid)
            .collection('skills')
            .doc(_skills[skillIndex].id)
            .update({'xp': _skills[skillIndex].xp});
      }

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'isCompleted': task.isCompleted, 'updatedAt': now.toIso8601String()});

      _tasks[taskIndex] = _tasks[taskIndex].copyWith(updatedAt: now);
      notifyListeners();
    }
  }

  Future<void> togglePin(String taskId) async {
    if (_user == null) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    final wasUnpinned = !_tasks[taskIndex].isPinned;
    debugPrint('[AppState] togglePin: taskId=$taskId wasPinned=${!wasUnpinned} → nowPinned=$wasUnpinned newDate=${wasUnpinned ? today.toIso8601String() : _tasks[taskIndex].date.toIso8601String()}');
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(
      isPinned: wasUnpinned,
      date: wasUnpinned ? today : _tasks[taskIndex].date,
      updatedAt: now,
      pinnedUntil: wasUnpinned ? () => null : null,
    );
    notifyListeners();
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
          'isPinned': _tasks[taskIndex].isPinned,
          'date': _tasks[taskIndex].date.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          if (wasUnpinned) 'pinnedUntil': null,
        });
  }

  Future<void> unpinKeepToday(String taskId) async {
    if (_user == null) return;
    debugPrint('[AppState] unpinKeepToday: taskId=$taskId');
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(
      isPinned: false,
      date: today,
      updatedAt: now,
    );
    notifyListeners();
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
          'isPinned': false,
          'date': today.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
  }

  Future<void> togglePinTasks(List<String> taskIds, bool pinned) async {
    if (_user == null) return;
    debugPrint('[AppState] togglePinTasks: ${taskIds.length} tasks pinned=$pinned');

    final batch = _firestore.batch();
    final userTasksRef = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks');
    final today = DateUtils.dateOnly(DateTime.now());
    final now = DateTime.now();

    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          isPinned: pinned,
          date: pinned ? today : _tasks[index].date,
          updatedAt: now,
          pinnedUntil: pinned ? () => null : null,
        );
        batch.update(userTasksRef.doc(id), {
          'isPinned': pinned,
          'date': _tasks[index].date.toIso8601String(),
          'updatedAt': now.toIso8601String(),
          if (pinned) 'pinnedUntil': null,
        });
      }
    }

    notifyListeners();
    await batch.commit();
  }

  Future<void> endPinnedTaskToday(String taskId) async {
    if (_user == null) return;
    debugPrint('[AppState] endPinnedTaskToday: taskId=$taskId');
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;
    final now = DateTime.now();
    final yesterday = DateUtils.dateOnly(now).subtract(const Duration(days: 1));
    debugPrint('[AppState] endPinnedTaskToday: pinnedUntil=${yesterday.toIso8601String()}');
    _tasks[taskIndex] = _tasks[taskIndex].copyWith(
      isPinned: false,
      pinnedUntil: () => yesterday,
      updatedAt: now,
    );
    notifyListeners();
    await _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks')
        .doc(taskId)
        .update({
          'isPinned': false,
          'pinnedUntil': yesterday.toIso8601String(),
          'updatedAt': now.toIso8601String(),
        });
  }

  Future<void> toggleStar(String taskId) async {
    if (_user == null) return;
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      _tasks[taskIndex].isStarred = !_tasks[taskIndex].isStarred;
      debugPrint('[AppState] toggleStar: taskId=$taskId isStarred=${_tasks[taskIndex].isStarred}');
      final now = DateTime.now();
      _tasks[taskIndex] = _tasks[taskIndex].copyWith(updatedAt: now);
      notifyListeners();

      await _firestore
          .collection('users')
          .doc(_user!.uid)
          .collection('tasks')
          .doc(taskId)
          .update({'isStarred': _tasks[taskIndex].isStarred, 'updatedAt': now.toIso8601String()});
    }
  }

  Future<void> toggleStarTasks(List<String> taskIds, bool starred) async {
    if (_user == null) return;
    debugPrint('[AppState] toggleStarTasks: ${taskIds.length} tasks starred=$starred');

    final batch = _firestore.batch();
    final userTasksRef = _firestore
        .collection('users')
        .doc(_user!.uid)
        .collection('tasks');

    for (final id in taskIds) {
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index].isStarred = starred;
        batch.update(userTasksRef.doc(id), {'isStarred': starred});
      }
    }

    notifyListeners();
    await batch.commit();
  }

  Future<void> applyDailyPenalty() async {
    if (_user == null) return;
    debugPrint('[AppState] applyDailyPenalty: ${_skills.length} skills penalized');
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
