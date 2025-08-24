// import 'dart:convert';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// class FirebaseNotificationService {
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//   final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   // Initialize notifications
//   Future<void> initialize() async {
//     // Request permissions
//     NotificationSettings settings = await _firebaseMessaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print("User granted permission");
//     } else {
//       print("User declined or has not accepted permission");
//     }

//     // Set up local notifications
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//     await _localNotificationsPlugin.initialize(initializationSettings);

//     // Handle messages while app is in the foreground
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       _showNotification(message);
//     });

//     // Handle background messages
//     FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

//     // Token generation
//     String? token = await _firebaseMessaging.getToken();
//     print("FCM Token: $token");

//     // Now we just log the token, no need to send to the backend
//   }

//   Future<String> getToken() {
//     return _firebaseMessaging.getToken().then((token) {
//       print("FCM Token Retrieved: $token");
//       return token ?? '';
//     });
//   }

//   // Background message handler
//   static Future<void> _firebaseMessagingBackgroundHandler(
//       RemoteMessage message) async {
//     print("Background message: ${message.notification?.title}");
//   }

//   // Show local notification
//   Future<void> _showNotification(RemoteMessage message) async {
//     const AndroidNotificationDetails androidNotificationDetails =
//         AndroidNotificationDetails(
//       'default_channel', // Channel ID
//       'Default', // Channel name
//       channelDescription: 'Default channel for app notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );
//     const NotificationDetails notificationDetails =
//         NotificationDetails(android: androidNotificationDetails);

//     await _localNotificationsPlugin.show(
//       message.notification.hashCode,
//       message.notification?.title ?? '',
//       message.notification?.body ?? '',
//       notificationDetails,
//     );
//   }
// }
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class FirebaseNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Add a static navigator key to access navigation context
  static GlobalKey<NavigatorState>? navigatorKey;

  // Initialize notifications
  Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print("User granted permission");
    } else {
      print("User declined or has not accepted permission");
    }

    // Set up local notifications with tap handling
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Handle messages while app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle notification tap when app is in background or terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Check if app was launched from a notification
    RemoteMessage? initialMessage =
        await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // Token generation
    String? token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
  }

  Future<String> getToken() {
    return _firebaseMessaging.getToken().then((token) {
      print("FCM Token Retrieved: $token");
      return token ?? '';
    });
  }

  // Background message handler
  static Future<void> _firebaseMessagingBackgroundHandler(
      RemoteMessage message) async {
    print("Background message: ${message.notification?.title}");
  }

  // Handle notification tap from local notifications
  void _onNotificationTapped(NotificationResponse response) {
    print("Notification tapped: ${response.payload}");
    _navigateToAnnouncements();
  }

  // Handle notification tap from Firebase messages
  void _handleNotificationTap(RemoteMessage message) {
    print("Firebase notification tapped: ${message.notification?.title}");
    _navigateToAnnouncements();
  }

  // Navigate to announcements screen
  void _navigateToAnnouncements() {
    if (navigatorKey?.currentContext != null) {
      Navigator.of(navigatorKey!.currentContext!).pushNamedAndRemoveUntil(
          '/announcements', (route) => route.settings.name == '/home');
    }
  }

  // Show local notification
  Future<void> _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'default_channel', // Channel ID
      'Default', // Channel name
      channelDescription: 'Default channel for app notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);

    await _localNotificationsPlugin.show(
      message.notification.hashCode,
      message.notification?.title ?? '',
      message.notification?.body ?? '',
      notificationDetails,
      payload: 'announcements', // Add payload for identification
    );
  }
}
