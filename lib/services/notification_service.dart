import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart'; // Added

import '../models/models.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // Initialize timezone data
    tz_data.initializeTimeZones();
    
    // Dynamically detect local timezone
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      // In newer versions of flutter_timezone, this might return a TimezoneInfo object.
      // We convert it to string to get the timezone ID.
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
      debugPrint('🔔 [NotificationService] TimeZone detected: ${tz.local.name}');
    } catch (e) {
      debugPrint('⚠️ [NotificationService] TimeZone detection failed, falling back to Asia/Dhaka: $e');
      try {
        tz.setLocalLocation(tz.getLocation("Asia/Dhaka"));
      } catch (e2) {
        debugPrint('❌ [NotificationService] Fallback failed: $e2');
      }
    }
    
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/launcher_icon');
    
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        debugPrint('🔔 [NotificationService] Notification tapped: ${details.payload}');
      },
    );

    // Request permissions for Android 13+
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      final bool? notifGranted = await androidPlugin.requestNotificationsPermission();
      final bool? exactGranted = await androidPlugin.requestExactAlarmsPermission();
      debugPrint('🔔 [NotificationService] Permissions - Notifications: $notifGranted, Exact Alarms: $exactGranted');
    }
  }

  // Helper for debugging
  String get currentTimeInfo => "Device: ${DateTime.now().toString().split('.')[0]}\nApp TZ: ${tz.local.name}";

  Future<void> showImmediateNotification() async {
    debugPrint('🔔 [NotificationService] Attempting immediate notification...');
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'test_channel_v3', // Fresh ID
      'Urgent Alerts',
      channelDescription: 'Critical tests and immediate feedback',
      importance: Importance.max,
      priority: Priority.max,
      showWhen: true,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true, // Try to pop up
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );
    
    try {
      await _notifications.show(
        id: 999,
        title: 'Immediate Test Notification',
        body: 'If you see this, the system is working! ✅',
        notificationDetails: details,
        payload: 'test_payload',
      );
      debugPrint('✅ [NotificationService] Immediate notification sent successfully');
    } catch (e) {
      debugPrint('❌ [NotificationService] Immediate notification FAILED: $e');
    }
  }

   Future<void> scheduleHabitReminder(Habit habit, {int? wakeMinutes, int? sleepMinutes}) async {
    // Cancel existing reminders first to avoid duplicates
    await cancelHabitReminder(habit);

    final List<Map<String, int>> times = [];
    
    if (habit.reminderHour != null && habit.reminderMinute != null) {
      times.add({'hour': habit.reminderHour!, 'minute': habit.reminderMinute!});
    }
    
    if (habit.reminderTimes != null && habit.reminderTimes!.isNotEmpty) {
      for (var t in habit.reminderTimes!) {
        bool exists = times.any((e) => e['hour'] == t['hour'] && e['minute'] == t['minute']);
        if (!exists) times.add(t);
      }
    }

    // Filter by active hours if provided
    if (wakeMinutes != null && sleepMinutes != null) {
      times.removeWhere((t) {
        int current = t['hour']! * 60 + t['minute']!;
        if (sleepMinutes > wakeMinutes) {
          return !(current >= wakeMinutes && current <= sleepMinutes);
        } else {
          return !(current >= wakeMinutes || current <= sleepMinutes);
        }
      });
    }

    if (times.isEmpty) {
       debugPrint('ℹ️ [NotificationService] No times to schedule for ${habit.title}');
       return;
    }

    // Use tz.TZDateTime.now(tz.local) for reliable timezone-aware scheduling
    final now = tz.TZDateTime.now(tz.local);
    
    for (int i = 0; i < times.length; i++) {
      final time = times[i];
      final hour = time['hour']!;
      final minute = time['minute']!;
      
      // Use consistent ID calculation with modulo 1,000,000 and separators to avoid 11:05/01:15 collision
      final String idString = '${habit.title}_${hour}_$minute';
      final int notificationId = idString.hashCode.abs() % 1000000;
      
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If the scheduled time is in the past for today, move to tomorrow
      // Added a 60-second buffer to handle processing delay and avoid "just missed" issues
      if (scheduledDate.isBefore(now.add(const Duration(seconds: 60)))) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      try {
        await _notifications.zonedSchedule(
          id: notificationId,
          title: 'Life Tracker',
          body: 'Habit Reminder: ${habit.title}',
          scheduledDate: scheduledDate,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders_v12', // Version bump to v12
              'Habit Reminders',
              channelDescription: 'Main triggers for habit progress',
              importance: Importance.max,
              priority: Priority.max,
              playSound: true,
              enableVibration: true,
              category: AndroidNotificationCategory.alarm, // Changed to alarm
              visibility: NotificationVisibility.public,
              fullScreenIntent: true,
              audioAttributesUsage: AudioAttributesUsage.alarm,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
        debugPrint('✅ [NotificationService] Scheduled habit at $scheduledDate (ID: $notificationId)');
      } catch (e) {
        debugPrint('❌ [NotificationService] Scheduling FAILED for ${habit.title}: $e');
        rethrow;
      }
    }
  }

  Future<void> scheduleSystemReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'system_alerts_v1',
            'System Alerts',
            channelDescription: 'Important reminders for streaks and daily plans',
            importance: Importance.max,
            priority: Priority.max,
            playSound: true,
            visibility: NotificationVisibility.public,
          ),
          iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      debugPrint('✅ [NotificationService] System reminder scheduled: $title at $scheduledDate (ID: $id)');
    } catch (e) {
      debugPrint('❌ [NotificationService] Error scheduling system reminder: $e');
    }
  }

  Future<void> cancelHabitReminder(Habit habit) async {
    // 1. Cancel legacy ID if any (original legacy)
    await _notifications.cancel(id: habit.title.hashCode.abs());
    
    // 2. Cancel legacy ID with modulo
    await _notifications.cancel(id: habit.title.hashCode.abs() % 1000000);
    
    // 3. Cancel all possible time-based IDs using separators
    if (habit.reminderTimes != null) {
      for (var t in habit.reminderTimes!) {
        final id = '${habit.title}_${t['hour']}_${t['minute']}'.hashCode.abs() % 1000000;
        await _notifications.cancel(id: id);
      }
    }
    
    // 4. Cancel primary reminder ID
    if (habit.reminderHour != null && habit.reminderMinute != null) {
        final id = '${habit.title}_${habit.reminderHour}_${habit.reminderMinute}'.hashCode.abs() % 1000000;
        await _notifications.cancel(id: id);
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}
