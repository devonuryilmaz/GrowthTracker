import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'firebase/firebase_background_handler.dart';
import 'screens/home.dart';
import 'services/api_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.high,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? token;

  @override
  void initState() {
    super.initState();
    initFCM();
  }

  Future<void> initFCM() async {
    final messaging = FirebaseMessaging.instance;
    final ApiService apiService = ApiService();
    final String platform = Platform.isAndroid ? 'Android' : 'iOS'; // Bu satırı değiştirin

    NotificationSettings settings = await messaging.requestPermission(
        alert: true, badge: true, sound: true, provisional: false);

    print('User granted permission: ${settings.authorizationStatus}');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.messageId}');

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/ic_launcher', // Bunu ekleyin veya kendi ikonunuzun adını yazın
              ),
              iOS: const DarwinNotificationDetails(),
            ),
            payload: jsonEncode(message.data));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Message clicked!: ${message.messageId}');

      _handleMessageClick(message);
    });

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageClick(initialMessage);
    }

    String? fcmToken = await messaging.getToken();
    setState(() {
      token = fcmToken;
    });
    print('FCM Token: $fcmToken');
    if (fcmToken != null) {
      await apiService.sendTokenToServer(fcmToken, platform );
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((event) async {
      print('FCM Token refreshed: $event');
      setState(() {
        token = event;
      });
      await apiService.sendTokenToServer(event, platform);
    });
  }

  void _handleMessageClick(RemoteMessage message) {
    // Handle notification click
    print('Notification clicked with data: ${message.data}');
    final data = message.data;
    final route = data['route'];
    Navigator.of(context).pushNamed(route, arguments: data);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Growth Tracker',
      home: HomeScreen(),
    );
  }
}
