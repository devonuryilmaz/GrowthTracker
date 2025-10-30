import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  log('Firebase Background Message Received: ${message.messageId}');
}