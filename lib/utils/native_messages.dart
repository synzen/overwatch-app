import 'package:flutter/services.dart';

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
