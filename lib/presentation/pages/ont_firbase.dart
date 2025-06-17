import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();

  // تهيئة الإشعارات
  Future<void> initialize() async {
    // طلب الإذن (لـ iOS)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // تهيئة إعدادات الإشعارات المحلية
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher'); // أيقونة التطبيق
    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: initializationSettingsAndroid,
      // iOS: يمكن إضافة إعدادات iOS هنا
    );
    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // معالجة الإشعارات عند فتح التطبيق
    FirebaseMessaging.onMessage.listen(_showNotification);

    // الحصول على token الجهاز (مهم لإرسال إشعارات مخصصة)
    String? token = await _firebaseMessaging.getToken();
    print('FCM Token: $token');
  }

  // عرض الإشعار
  Future<void> _showNotification(RemoteMessage message) async {
    AndroidNotificationDetails androidPlatformChannelSpecifics =
    const AndroidNotificationDetails(
      'high_importance_channel', // معرّف القناة
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      // iOS: يمكن إضافة إعدادات iOS هنا
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // معرّف الإشعار (يجب أن يكون فريدًا لكل إشعار)
      message.notification?.title ?? 'New Notification',
      message.notification?.body ?? 'You have a new message',
      platformChannelSpecifics,
    );
  }

  // معالجة الإشعارات في الخلفية (مطلوب ملف منفصل)
  @pragma('vm:entry-point')
  static Future<void> backgroundHandler(RemoteMessage message) async {
    await NotificationService()._showNotification(message);
  }
}

