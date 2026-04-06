import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import '../models/task.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _dailySummaryId = 0;
  // Time-specific task notifications use IDs starting from 1000
  static const int _timeTaskBaseId = 1000;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings = AndroidInitializationSettings('@drawable/ic_notification');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(initSettings);
  }

  Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
    }
  }

  /// Reschedule all notifications based on current tasks.
  /// Call this after: addTask, updateTask, completeTask, deleteTask, app launch.
  Future<void> rescheduleAll(List<Task> tasks) async {
    // Cancel all existing notifications
    await _plugin.cancelAll();

    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    // Filter tasks for today: non-pinned, non-completed
    final todayTasks = tasks.where((t) {
      final todayStr = today.toIso8601String().split('T')[0];
      
      // Skip completed tasks
      if (!t.isPinned && t.isCompleted) return false;
      if (t.isPinned && t.completedDates.contains(todayStr)) return false;
      
      // Include pinned tasks ONLY if notifyEnabled
      if (t.isPinned) return t.notifyEnabled;
      
      // Non-pinned: must be today's date
      return DateUtils.dateOnly(t.date) == today;
    }).toList();

    // Split into timed and untimed
    final timedTasks = todayTasks.where((t) => t.time != null).toList();
    final untimedTasks = todayTasks.where((t) => t.time == null).toList();

    // 1. Schedule daily summary at 8:00 AM (only if it hasn't passed yet)
    if (untimedTasks.isNotEmpty) {
      final summaryTime = tz.TZDateTime(
        tz.local,
        today.year,
        today.month,
        today.day,
        8, // 8:00 AM
        0,
      );

      if (summaryTime.isAfter(now)) {
        String title = 'RPG Tasks';
        String body;
        if (untimedTasks.length == 1) {
          body = untimedTasks.first.title;
        } else {
          body = 'You have ${untimedTasks.length} quests today. Time to level up!';
        }

        await _scheduleNotification(
          id: _dailySummaryId,
          title: title,
          body: body,
          scheduledTime: summaryTime,
        );
      }
    }

    // 2. Schedule time-specific task notifications (1 hour before)
    for (int i = 0; i < timedTasks.length; i++) {
      final task = timedTasks[i];
      final taskTime = task.time!;
      final reminderTime = tz.TZDateTime(
        tz.local,
        taskTime.year,
        taskTime.month,
        taskTime.day,
        taskTime.hour,
        taskTime.minute,
      ).subtract(const Duration(hours: 1));

      if (reminderTime.isAfter(now)) {
        final timeStr = '${taskTime.hour.toString().padLeft(2, '0')}:${taskTime.minute.toString().padLeft(2, '0')}';
        await _scheduleNotification(
          id: _timeTaskBaseId + i,
          title: 'RPG Tasks',
          body: '${task.title} at $timeStr',
          scheduledTime: reminderTime,
        );
      }
    }
  }

  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'rpg_tasks_reminders',
      'Task Reminders',
      channelDescription: 'Notifications for upcoming tasks',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: null, // One-time, not repeating
    );
  }
}
