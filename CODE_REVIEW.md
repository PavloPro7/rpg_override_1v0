# Code Review — rpg_override_1v0

**Reviewer:** Claude Opus (strict mode)
**Date:** 2026-03-20
**Files reviewed:** 17 Dart files, pubspec.yaml
**Verdict:** Solid MVP with real architectural risks that will hurt you at scale.

---

## CRITICAL — Fix Before Shipping

### 1. Mutable fields on "model" objects (task.dart, skill.dart)

`Task.isCompleted`, `Task.isStarred`, `Task.isPinned`, `Task.completedDates`, and `Skill.xp` are **mutable**. You have `copyWith`, but half the codebase mutates directly instead:

```dart
// app_state.dart line 774
task.isCompleted = !task.isCompleted;

// app_state.dart line 1003
_tasks[taskIndex].isStarred = !_tasks[taskIndex].isStarred;

// app_state.dart lines 755-758
task.completedDates.remove(dateStr);
task.completedDates.add(dateStr);

// skill.dart line 62-64
void addXp(double amount) { xp += amount; }
```

**Why this is critical:** You mutate the object, then call `copyWith` on the same object for `updatedAt`, then call `notifyListeners()`. Provider compares object references. If a widget somewhere caches the old reference, it sees the mutation without a rebuild. This is a class of bugs that appears randomly and is impossible to reproduce reliably. It's the root cause of many of your "ghost" UI issues.

**Fix:** Make ALL fields `final`. Use `copyWith` exclusively. For `completedDates`, return a new `List` every time.

### 2. God class: AppState (1063 lines)

`AppState` handles: authentication (5 methods), profile management, theme, preferences, skills CRUD, tasks CRUD, pinning, starring, completing, XP calculation, Firestore sync, daily penalties. This is a single `ChangeNotifier` that fires `notifyListeners()` for everything.

**Why this is critical:** Every `notifyListeners()` rebuilds every `context.watch<AppState>()` widget in the entire app — dashboard, skills screen, task list, profile, settings. When you complete a task, the radar chart, profile screen, and settings all rebuild for no reason. This is why you see "skipped 113 frames" in your logs.

**Fix (incremental):** Split into at least `AuthProvider`, `TaskProvider`, `SkillProvider`. Or use `select()` to only watch specific fields. Long-term: consider Riverpod, which handles this naturally.

### 3. No Firestore error handling on writes

Every Firestore write in the app is fire-and-forget:

```dart
_tasks.add(newTask);
notifyListeners();
await _firestore...doc(newTask.id).set(newTask.toMap());
// What if this fails? Local state says task exists. Firestore says it doesn't.
```

There is zero `try/catch` on any task/skill write operation (`addTask`, `updateTaskContent`, `deleteTasks`, `completeTask`, `togglePin`, `toggleStar`, etc.). If the user loses internet for 1 second, local state and Firestore diverge permanently.

**Fix:** Wrap every Firestore write in try/catch. On failure, either rollback local state or queue for retry.

### 4. Skill deletion leaves orphaned tasks

`removeSkill` deletes the skill from Firestore but does NOT update tasks that reference that `skillId`. In `_buildTaskTile` and `dashboard_screen.dart`, there's a fallback:

```dart
orElse: () => appState.skills.first,
```

If a user deletes the skill that their tasks point to, those tasks now show the color/name of `skills.first` — a random skill. If ALL skills are deleted, this crashes with `StateError: No element`.

**Fix:** When deleting a skill, either reassign its tasks to 'none' or prevent deletion if tasks reference it.

---

## HIGH — Will Cause User-Facing Bugs

### 5. `resetAccount` deletes skills from Firestore but doesn't re-seed them

```dart
// Deletes all tasks ✓
// Sets name/age back to Hero/0 ✓
// _skills = _initialSkills() — which returns [] !
```

After reset, the user has zero skills and `_initialSkills()` returns an empty list. The onboarding screen shows "Choose Skills" with nothing to choose from. Skills are only seeded in `_loadFromFirestore` when `skillsSnapshot.docs.isEmpty`, but `resetAccount` doesn't delete skills from Firestore — it only deletes tasks. So after reset: Firestore has old skills, local state has empty list, but `_loadFromFirestore` won't re-seed because the Firestore collection isn't empty. Inconsistent state.

### 6. `deleteAccount` calls `signOut()` before `currentUser?.delete()`

```dart
await signOut();                // clears _user, clears local state
await currentUser?.delete();    // tries to delete auth account
```

`signOut()` triggers the `authStateChanges` listener which sets `_user = null`, clears tasks, etc. Then you try to delete the Firebase Auth account. This works only because you saved a reference to `currentUser` before — but the Firebase SDK may reject the delete because the session is already ended. This is a race condition.

### 7. Double-sorting in skills_screen.dart

The `_showRecentTasksBottomSheet` sorts tasks in the `.then()` callback of the Future, then sorts again in the `builder:`. The `.then()` sort is wasted work because it returns the original unsorted snapshot (the sorted `docs` list is created locally and discarded).

### 8. XP calculation uses floating point

```dart
xp += amount;  // double
final double xpAmount = 30.0 * (task.difficulty / 5.0);
```

After many additions/subtractions, floating point drift accumulates. A user who completes and uncompletes a task 100 times won't have the same XP they started with. Use `int` (store XP in centipunits) or at least round after each operation.

### 9. `endPinnedTaskToday` sets `pinnedUntil` to YESTERDAY

```dart
final yesterday = DateUtils.dateOnly(now).subtract(const Duration(days: 1));
_tasks[taskIndex] = _tasks[taskIndex].copyWith(
  isPinned: false,
  pinnedUntil: () => yesterday,
);
```

The intent is "stop showing this task from today forward." But if the user opens the app tomorrow, this task will still show on every date from `task.date` to `yesterday` (which was today-1). The comment says "end today" but the behavior is "end yesterday." If the user meant "I'm done with this task TODAY, don't show it TOMORROW," then `pinnedUntil` should be `today`, not `yesterday`.

### 10. `getTasksForDate` diagnostic logging left in production code

The current `getTasksForDate` has verbose `debugPrint` for every pinned task on every frame. `PageView.builder` calls this on every scroll tick. With 59 tasks and swiping, this produces hundreds of log lines per second. Even `debugPrint` has overhead (string interpolation, platform channel). Remove or guard behind a `kDebugMode` flag.

---

## MEDIUM — Code Quality / Maintainability

### 11. Massive code duplication across screens

`ProfileScreen`, `SettingsScreen`, and `LoginScreen` all have their own copies of: `_showEditProfileDialog` (~60 lines), `_showChangeEmailDialog` (~50 lines), `_showChangePasswordDialog` (~50 lines), `_buildSectionCard`, `_buildActionRow`. That's ~300 lines of identical code across 3 files. Any bug fix needs to be applied in 3 places.

**Fix:** Extract these into shared widgets or a dialog utility class (you already have `SkillDialogUtils` — use the same pattern).

### 12. `Skill.id` is derived from name

```dart
id: name.toLowerCase().replaceAll(' ', '_'),
```

If a user creates "My Skill" then renames it, the ID stays as `my_skill`. If they create another skill called "My Skill", it gets the same ID and overwrites the first one in Firestore. No uniqueness check exists.

**Fix:** Use UUID for skill IDs, same as tasks.

### 13. `task_list.dart` is 1000+ lines

This single file contains: the screen widget, date selector, page view, task tiles, completion animation, selection mode, unpin dialog, move dialog, add/edit task dialog, date picker, completion burst animation widget. It should be split into at least 5 files.

### 14. `AnimatedBuilder` is not a real Flutter widget

```dart
child: AnimatedBuilder(
  animation: _pageController,
  builder: (context, child) { ... }
)
```

The correct class name is `AnimatedBuilder` — wait, actually it IS `AnimatedBuilder` in newer Flutter versions (alias for `AnimatedWidget`). However, the pattern here rebuilds the entire date selector on every scroll pixel. Consider `ValueListenableBuilder` or a custom `ScrollController` listener that only updates on settled pages.

### 15. No input validation on task creation

The `_showAddTaskDialog` (in task_list.dart) and `addTask` (in app_state.dart) accept any string including empty strings. There's no max length. A user could create a task with a 10,000-character title and it would be stored in Firestore, rendered in a `ListTile`, and overflow everything.

### 16. `color.value` is deprecated

```dart
// skill.dart line 26
'color': color.value,  // deprecated in Flutter 3.27+
```

Use `color.toARGB32()` or store as hex string.

---

## LOW — Nit-picks / Style

### 17. Inconsistent date handling

Some places use `DateUtils.dateOnly()`, others use `DateFormat('yyyy-MM-dd').format()`. The `Task.date` field stores a `DateTime` that may or may not have a time component depending on where it was created. Standardize: always strip time with `DateUtils.dateOnly()` at the model level (in `fromMap`).

### 18. `_initialSkills()` always returns empty list

```dart
List<Skill> _initialSkills() => [];
```

This is called in the constructor and in `resetAccount`. It does nothing. Either implement default skills or remove it.

### 19. `DropdownButtonFormField.initialValue` doesn't exist

```dart
// settings_screen.dart line 77
initialValue: (appState.defaultSkillId == null || ...
```

The correct property is `value`, not `initialValue`. This might work in some Flutter versions but is technically wrong per the API.

### 20. Theme inconsistency between light/dark

Light theme uses `GoogleFonts.robotoTextTheme()`, dark theme uses `GoogleFonts.interTextTheme()`. Two different fonts for two different themes. This is probably unintentional.

### 21. Missing `mounted` checks

Several places use `context` after `await` without checking `mounted`:
- `_showMoveMultipleTasksDialog` → `Navigator.pop(context)` after `await`
- `_showForgotPasswordDialog` → uses `context.mounted` (correct) but also `Navigator.pop(context)` before the mounted check runs
- `deleteAccount` in settings_screen.dart → `Navigator.pop(context)` then `await appState.deleteAccount()` then uses `context.mounted`

### 22. No Firestore security rules mentioned

The app reads/writes directly to `users/{uid}/tasks` and `users/{uid}/skills`. Without proper Firestore security rules, any authenticated user could read/write other users' data. This is a Firebase Console configuration issue, not a code issue, but worth verifying.

---

## Architecture Summary

| Aspect | Rating | Notes |
|--------|--------|-------|
| Project structure | 6/10 | Flat and simple, but task_list.dart is too large |
| State management | 4/10 | Single god-class ChangeNotifier, mutable models |
| Firebase integration | 5/10 | Works, but no error handling, no offline support |
| UI/UX code | 7/10 | Clean Material 3 design, good animations |
| Code reuse | 4/10 | Heavy duplication across profile/settings |
| Data integrity | 3/10 | Mutable models, no validation, orphan references |
| Scalability | 4/10 | Full task list in memory, rebuilds everything |
| Security | 5/10 | Depends entirely on Firestore rules |

**Overall: 5/10** — Functional MVP, but needs structural fixes before adding more features.

---

## Recommended Priority Order

1. Make Task and Skill fully immutable (fixes ghost bugs, prevents entire class of issues)
2. Add try/catch to all Firestore writes (prevents data corruption)
3. Remove diagnostic logging from getTasksForDate (performance)
4. Split AppState into 3 providers (performance, maintainability)
5. Extract duplicated dialogs into shared widgets (maintainability)
6. Fix Skill.id to use UUID (prevents data loss)
7. Add input validation (prevents edge case crashes)
