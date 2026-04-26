import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase/firebase_background_handler.dart';
import 'providers/user_provider.dart';
import 'providers/task_provider.dart';
import 'providers/stats_provider.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // id
  'High Importance Notifications', // title
  description:
      'This channel is used for important notifications.', // description
  importance: Importance.high,
);

bool _firebaseInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    _firebaseInitialized = true;
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization skipped: $e');
  }

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
    if (!_firebaseInitialized) return;

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

    final prefs = await SharedPreferences.getInstance();
    final String? userId = prefs.getString('userId');

    String? fcmToken = await messaging.getToken();
    setState(() {
      token = fcmToken;
    });
    print('FCM Token: $fcmToken');
    if (fcmToken != null) {
      await prefs.setString('fcm_token', fcmToken);
      if (userId != null && userId.isNotEmpty) {
        await apiService.sendTokenToServer(fcmToken, platform, userId: userId);
      }
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((event) async {
      print('FCM Token refreshed: $event');
      setState(() {
        token = event;
      });
      final refreshPrefs = await SharedPreferences.getInstance();
      await refreshPrefs.setString('fcm_token', event);
      final String? refreshUserId = refreshPrefs.getString('userId');
      if (refreshUserId != null && refreshUserId.isNotEmpty) {
        await apiService.sendTokenToServer(event, platform, userId: refreshUserId);
      }
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => StatsProvider()),
      ],
      child: MaterialApp(
        title: 'Growth Tracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        themeMode: ThemeMode.light,
        home: const _AppStartup(),
      ),
    );
  }
}

/// İlk açılışta SharedPreferences'ta userId varsa Home'a, yoksa Login'e yönlendir.
class _AppStartup extends StatefulWidget {
  const _AppStartup();

  @override
  State<_AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<_AppStartup> {
  @override
  void initState() {
    super.initState();
    _checkFirstRun();
  }

  Future<void> _checkFirstRun() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');

    if (!mounted) return;

    if (userId != null && userId.isNotEmpty) {
      // Provider'ı doldur
      await context.read<UserProvider>().loadFromPrefs();
      if (!mounted) return;

      // Returning user: daha önce kaydedilmemiş token varsa kaydet
      final fcmToken = prefs.getString('fcm_token');
      if (fcmToken != null) {
        final platform = Platform.isAndroid ? 'Android' : 'iOS';
        await ApiService().sendTokenToServer(fcmToken, platform, userId: userId);
      }

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}
