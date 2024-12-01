import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationHandler {
  NotificationHandler._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static void initialize() {
    AndroidInitializationSettings androidInitializationSettings =
    const AndroidInitializationSettings('@mipmap/ic_launcher');
    DarwinInitializationSettings darwinInitializationSettings =
    const DarwinInitializationSettings();

    InitializationSettings initializationSettings = InitializationSettings(
        android: androidInitializationSettings,
        iOS: darwinInitializationSettings);

    _plugin.initialize(initializationSettings);
  }

  static Future<bool> getPermission() async {
    FirebaseMessaging.instance.requestPermission();
    bool? permissionGranted = await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    return permissionGranted ?? false;
  }

  static void handleForegroundNotification() {
    FirebaseMessaging.onMessage.listen((RemoteMessage remoteMessage) => _showNotification(remoteMessage, 'onMessage'));

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage remoteMessage) => _showNotification(remoteMessage, 'onMessageOpenedApp'));
  }

  static void handleBackgroundNotification() {
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessageHandler);
  }

  static Future<void> _showNotification(RemoteMessage remoteMessage, String message) async {
    viewNotification(remoteMessage, message);
  }

  static void viewNotification(RemoteMessage remoteMessage, String message) {
    AndroidNotificationDetails androidNotificationDetails =
        const AndroidNotificationDetails(
      'id',
      'name',
      autoCancel: true,
      importance: Importance.high,
      priority: Priority.high,
      enableLights: true,
      enableVibration: true,
    );

    DarwinNotificationDetails darwinNotificationDetails = const DarwinNotificationDetails(presentBadge: true, presentSound: true, presentAlert: true);

    NotificationDetails notificationDetails = NotificationDetails(
        android: androidNotificationDetails,
        iOS: darwinNotificationDetails);

    if (remoteMessage.notification != null) {
      _plugin.show(remoteMessage.hashCode, remoteMessage.notification!.title, remoteMessage.notification!.body, notificationDetails);
    }
  }
}

Future<void> _onBackgroundMessageHandler(RemoteMessage remoteMessage) async {
  NotificationHandler._showNotification(remoteMessage, 'onBackgroundMessage');
}