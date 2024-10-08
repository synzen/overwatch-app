import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:overwatchapp/types/monitored_commute.types.dart';
import 'package:overwatchapp/utils/app_container.dart';
import 'package:overwatchapp/utils/native_messages.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const prod = bool.fromEnvironment('dart.vm.product');

@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  FlutterTts? tts;
  TransitApi? transitApi;

  Future<void> handleTask() async {
    if (transitApi == null) {
      await dotenv.load(fileName: prod ? '.env.prod' : '.env');
      transitApi = TransitApi.fromEnv();
    }

    var commuteStr =
        await FlutterForegroundTask.getData<String>(key: "commute");

    if (commuteStr == null) {
      return;
    }

    var commute = MonitoredCommute.fromJsonString(commuteStr);

    var arrivalTime = await transitApi!.fetchArrivalTimes(
        commute.stops.map((s) => s.id).toList(),
        commute.stops.map((s) => s.routeId).toList());

    var fastestArrival = arrivalTime.data.arrivals.elementAtOrNull(0);

    var newTimerDuration = const Duration(minutes: 3);

    var estimateText = "No arrival time available";

    final Map<String, dynamic> data = {
      "event": "updateTimer",
      "newTimerDuration": newTimerDuration.inMilliseconds,
      "estimateText": estimateText,
      "arrivalTimes": arrivalTime.toJson(),
    };

    if (fastestArrival == null) {
      FlutterForegroundTask.sendDataToMain(data);

      return;
    }

    if (fastestArrival.minutesUntilArrival < 3) {
      newTimerDuration = const Duration(seconds: 30);
    } else if (fastestArrival.minutesUntilArrival < 5) {
      newTimerDuration = const Duration(minutes: 1);
    } else if (fastestArrival.minutesUntilArrival < 7) {
      newTimerDuration = const Duration(minutes: 2);
    }

    String text;

    if (fastestArrival.minutesUntilArrival == 0) {
      text = "${fastestArrival.routeLabel} arriving now";
    } else {
      text =
          "${fastestArrival.routeLabel} in ${fastestArrival.minutesUntilArrival} minute${fastestArrival.minutesUntilArrival > 1 ? 's' : ''}";
    }

    var nextFastestArrival = arrivalTime.data.arrivals.elementAtOrNull(1);

    if (nextFastestArrival != null &&
        nextFastestArrival.minutesUntilArrival < 6) {
      text +=
          ", ${nextFastestArrival.routeLabel} in ${nextFastestArrival.minutesUntilArrival} minutes";
    }

    data["newTimerDuration"] = newTimerDuration.inMilliseconds;
    data["estimateText"] = text;

    FlutterForegroundTask.sendDataToMain(data);
  }

  // Called when the task is started.
  @override
  void onStart(DateTime timestamp) {
    print('onStart');
  }

  // Called every [ForegroundTaskOptions.interval] milliseconds.
  @override
  void onRepeatEvent(DateTime timestamp) {
    printForDebugging('onRepeat 2');

    handleTask().catchError((e, stackTrace) {
      printForDebugging('Error in task: $e');
      printForDebugging(stackTrace);
    });
  }

  // Called when the task is destroyed.
  @override
  void onDestroy(DateTime timestamp) {
    print('onDestroy');
  }

  // Called when data is sent using [FlutterForegroundTask.sendDataToTask].
  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
  }

  // Called when the notification button on the Android platform is pressed.
  @override
  void onNotificationButtonPressed(String id) {
    print('onNotificationButtonPressed: $id');
    if (id == "stop_monitoring") {
      final Map<String, dynamic> data = {
        "event": "stop",
      };

      FlutterForegroundTask.sendDataToMain(data);
    }
  }

  // Called when the notification itself on the Android platform is pressed.
  //
  // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
  // this function to be called.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp('/');
    print('onNotificationPressed');
  }

  // Called when the notification itself on the Android platform is dismissed
  // on Android 14 which allow this behaviour.
  @override
  void onNotificationDismissed() {
    print('onNotificationDismissed');
  }
}

class CommuteMonitoringService extends ChangeNotifier {
  MonitoredCommute? _monitoredCommute;
  int timerDurationMs = 3 * 60 * 1000;
  String? estimateText;
  GetTransitStopArrivalTime? arrivalTimes;

  CommuteMonitoringService() {
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }

  Future<void> _speak(String text) async {
    var headphoneStatus = await sendHeadphonesPluggedStatusCheck();

    if (!headphoneStatus.pluggedIn) {
      printForDebugging('Headphones not plugged in');
      return;
    }

    printForDebugging('Speaking: $text');

    try {
      await appContainer.get<FlutterTts>().speak(text);
    } catch (e) {
      printForDebugging('Error speaking: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      // "android.permission.SYSTEM_ALERT_WINDOW" permission must be granted for
      // onNotificationPressed function to be called.
      //
      // When the notification is pressed while permission is denied,
      // the onNotificationPressed function is not called and the app opens.
      //
      // If you do not use the onNotificationPressed or launchApp function,
      // you do not need to write this code.
      if (!await FlutterForegroundTask.canDrawOverlays) {
        // This function requires `android.permission.SYSTEM_ALERT_WINDOW` permission.
        await FlutterForegroundTask.openSystemAlertWindowSettings();
      }

      // Android 12 or higher, there are restrictions on starting a foreground service.
      //
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }

      // Android 13 and higher, you need to allow notification permission to expose foreground service notification.
      final NotificationPermission notificationPermissionStatus =
          await FlutterForegroundTask.checkNotificationPermission();
      if (notificationPermissionStatus != NotificationPermission.granted) {
        await FlutterForegroundTask.requestNotificationPermission();
      }
    }
  }

  Future<void> _initService(String commuteName) async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
          id: 123,
          channelId: 'foreground_service',
          channelName: 'Foreground Service Notification',
          channelImportance: NotificationChannelImportance.MAX,
          priority: NotificationPriority.MAX,
          visibility: NotificationVisibility.VISIBILITY_PUBLIC),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        interval: timerDurationMs,
        isOnceEvent: false,
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  void _onReceiveTaskData(dynamic data) {
    if (data is! Map<String, dynamic>) {
      printForDebugging('Invalid task data: $data');
      return;
    }

    if (data["event"] == "stop") {
      printForDebugging('Stopping service');
      FlutterForegroundTask.stopService();
      _monitoredCommute = null;
      notifyListeners();
      return;
    }

    final dynamic timestampMillis = data["newTimerDuration"];

    if (timestampMillis == null) {
      printForDebugging('No timestamp in task data');
      return;
    }

    if (timestampMillis is! int) {
      printForDebugging('Invalid timestamp in task data: $timestampMillis');
      return;
    }

    if (timestampMillis != timerDurationMs) {
      printForDebugging(
          'Timestamp is the same as current timer: $timestampMillis');

      timerDurationMs = timestampMillis;

      printForDebugging('UPDATING TIMER: $timestampMillis');

      FlutterForegroundTask.updateService(
              notificationText: data["estimateText"],
              foregroundTaskOptions:
                  ForegroundTaskOptions(interval: timestampMillis))
          .catchError((err) {
        printForDebugging(
            'Error updating foreground service timer: ${err.toString()}');

        return err;
      });
    }

    estimateText = data["estimateText"];
    arrivalTimes = data["arrivalTimes"] != null
        ? GetTransitStopArrivalTime.fromJson(data["arrivalTimes"])
        : null;

    _speak(estimateText!);

    notifyListeners();
  }

  Future<ServiceRequestResult> _startService(
      String name, List<CommuteRouteStop> stops) async {
    final dataToSave = MonitoredCommute(
      name: name,
      stops: stops,
    ).toJsonString();

    printForDebugging('Saving data: $dataToSave');

    await FlutterForegroundTask.saveData(key: "commute", value: dataToSave);
    if (await FlutterForegroundTask.isRunningService) {
      printForDebugging('service is already running');
      return FlutterForegroundTask.restartService();
    } else {
      printForDebugging('service is not running');
      return FlutterForegroundTask.startService(
        notificationTitle: 'Monitoring commute: $name',
        notificationText: '',
        notificationButtons: [
          const NotificationButton(
            id: 'stop_monitoring',
            text: 'Stop monitoring',
          ),
        ],
        callback: startCallback,
      );
    }
  }

  MonitoredCommute? get monitoredCommute => _monitoredCommute;

  Future<void> startMonitoring(
      String commuteName, List<CommuteRouteStop> stops) async {
    stopMonitoring();
    await _requestPermissions();
    await _initService(commuteName);
    await _startService(commuteName, stops);
    printForDebugging('service started');

    _monitoredCommute = MonitoredCommute(name: commuteName, stops: stops);

    notifyListeners();
  }

  void stopMonitoring() {
    FlutterForegroundTask.stopService();

    _monitoredCommute = null;
    arrivalTimes = null;
    estimateText = null;
    notifyListeners();
  }
}
