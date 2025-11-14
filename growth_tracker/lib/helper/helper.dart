import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

Future<String> getDeviceId() async {
  final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
  String deviceId = '';

  try {
    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
      deviceId = androidInfo.id ?? '';
    } else if (Platform.isIOS) {
      IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosInfo.identifierForVendor ?? '';
    }
  } catch (e) {
    print('Error getting device ID: $e');
  }

  return deviceId;
}