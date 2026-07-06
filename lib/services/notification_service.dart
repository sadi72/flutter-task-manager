import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final notification = FlutterLocalNotificationsPlugin();

  static Future init() async {
    tz_data.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    
    await notification.initialize(settings);

    await notification.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    
    await notification.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();
  }

  static Future show(String title) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'tasks',
        'Tasks',
        importance: Importance.max,
        priority: Priority.high,
      ),
    );
    await notification.show(0, "Reminder", title, details);
  }

  static Future scheduleNotification(int id, String title, DateTime scheduledDate) async {
    await notification.zonedSchedule(
      id,
      "Task Reminder",
      title,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_alarms',
          'Task Alarms',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future cancelNotification(int id) async {
    await notification.cancel(id);
  }
}
