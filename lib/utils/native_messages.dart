import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:overwatchapp/utils/print_debug.dart';

const MethodChannel nativePlatform = MethodChannel("com.synzen.overwatch");

class CreateNativeNotification {
  final String description;
  final String title;
  const CreateNativeNotification(
      {required this.description, required this.title});
}

Future<void> initializeNativeMessaging() async {
  await nativePlatform.invokeMethod('initialize');
}

Future<void> sendNotification(CreateNativeNotification m) async {
  await nativePlatform.invokeMethod('sendNotification', {
    'description': m.description,
    'title': m.title,
  });
}

class HeadphoneStatusCheck {
  final bool pluggedIn;
  const HeadphoneStatusCheck({required this.pluggedIn});

  factory HeadphoneStatusCheck.fromJsonString(String jsonString) {
    var json = jsonDecode(jsonString);
    return HeadphoneStatusCheck(pluggedIn: json["pluggedIn"]);
  }
}

Future<HeadphoneStatusCheck> sendHeadphonesPluggedStatusCheck() async {
  try {
    var res = await nativePlatform.invokeMethod<String>('checkHeadphones');

    if (res == null) {
      throw Exception('Missing response from native platform');
    }

    return HeadphoneStatusCheck.fromJsonString(res);
  } catch (e) {
    printForDebugging('Error checking headphones state: $e');
    return const HeadphoneStatusCheck(pluggedIn: false);
  }
}
