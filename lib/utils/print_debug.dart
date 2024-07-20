import 'package:flutter/foundation.dart';

void printForDebugging(String message) {
  if (kDebugMode) {
    debugPrint("${DateTime.now().toIso8601String()}: $message");
  }
}
