import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../database/app_database.dart';
import '../database/tables.dart';
import 'package:drift/drift.dart' show Value;

part 'reminder_service.g.dart';

@Riverpod(keepAlive: true)
ReminderService reminderService(ReminderServiceRef ref) {
  final db = ref.watch(appDatabaseProvider);
  final svc = ReminderService(db);
  svc.init();
  return svc;
}

class ReminderService {
  final AppDatabase _db;
  final _plugin = FlutterLocalNotificationsPlugin();

  ReminderService(this._db);

  Future<void> init() async {
    tz.initializeTimeZones();
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // 可在此处理通知点击跳转
  }

  Future<void> scheduleReminder(Reminder reminder) async {
    if (!reminder.enabled) return;
    final scheduledTime = tz.TZDateTime.from(reminder.remindAt, tz.local);
    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      reminder.id,
      reminder.title,
      reminder.description ?? '',
      scheduledTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'flash_note_reminders',
          '闪记提醒',
          channelDescription: '笔记相关提醒通知',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelReminder(int reminderId) async {
    await _plugin.cancel(reminderId);
  }

  Future<void> toggleReminder(Reminder reminder) async {
    final enabled = !reminder.enabled;
    await _db.updateReminder(RemindersCompanion(
      id: Value(reminder.id),
      enabled: Value(enabled),
    ));
    if (enabled) {
      await scheduleReminder(reminder);
    } else {
      await cancelReminder(reminder.id);
    }
  }

  /// 从 AI 分析结果中智能解析时间（简单实现，后续可接 NLP）
  DateTime? parseTimeHint(String timeHint) {
    final now = DateTime.now();
    final hint = timeHint.toLowerCase();

    if (hint.contains('明天') || hint.contains('tomorrow')) {
      final match = RegExp(r'(\d{1,2})点').firstMatch(hint);
      final hour = match != null ? int.parse(match.group(1)!) : 9;
      return DateTime(now.year, now.month, now.day + 1, hour);
    }
    if (hint.contains('后天')) {
      final match = RegExp(r'(\d{1,2})点').firstMatch(hint);
      final hour = match != null ? int.parse(match.group(1)!) : 9;
      return DateTime(now.year, now.month, now.day + 2, hour);
    }
    if (hint.contains('下周') || hint.contains('next week')) {
      return now.add(const Duration(days: 7));
    }
    // 尝试解析"X月X日"
    final dateMatch = RegExp(r'(\d{1,2})月(\d{1,2})日').firstMatch(hint);
    if (dateMatch != null) {
      final month = int.parse(dateMatch.group(1)!);
      final day = int.parse(dateMatch.group(2)!);
      final hourMatch = RegExp(r'(\d{1,2})点').firstMatch(hint);
      final hour = hourMatch != null ? int.parse(hourMatch.group(1)!) : 9;
      return DateTime(now.year, month, day, hour);
    }
    return null;
  }
}
