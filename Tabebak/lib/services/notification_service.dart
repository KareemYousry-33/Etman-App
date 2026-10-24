import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:get/get.dart';

class NotificationService extends GetxService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<NotificationService> init() async {
    try {
      tz.initializeTimeZones();
      
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _notificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (response.payload != null) {
            if (response.payload == 'appointments') {
              Get.toNamed('/patient-profile');
            }
          }
        },
      );
    } catch (e) {
      debugPrint('⚠️ NotificationService internal init error: $e');
    }
    return this;
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'etman_channel',
      'Etman Notifications',
      channelDescription: 'Notifications for Etman appointments',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'etman_engagement',
          'Etman Engagement',
          channelDescription: 'Motivational messages for Etman users',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: payload,
    );
  }

  Future<void> scheduleEngagementNotifications() async {
    // 1. Initial motivation message after 5 minutes
    await scheduleNotification(
      id: 1001,
      title: 'صحتك أولوية! 🌟',
      body: 'هل حجزت موعدك الدوري اليوم؟ دكاترة في كل التخصصات مستعدين لمساعدتك.',
      scheduledDate: DateTime.now().add(const Duration(minutes: 5)),
    );

    // 2. Daily reminder after 6 hours
    await scheduleNotification(
      id: 1002,
      title: 'كن إيجابياً! 💪',
      body: 'الوقاية خير من العلاج. تصفح أفضل الأطباء المتاحين الآن القريبين منك.',
      scheduledDate: DateTime.now().add(const Duration(hours: 6)),
    );

    // 3. Morning motivation (next day)
    await scheduleNotification(
      id: 1003,
      title: 'صباح الخير والنشاط ☀️',
      body: 'ابدأ يومك بالاطمئنان على صحتك. فريقنا الطبي معاك في أي وقت.',
      scheduledDate: DateTime.now().add(const Duration(hours: 24)),
    );
  }
}
