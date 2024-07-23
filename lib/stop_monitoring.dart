import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:overwatchapp/utils/app_container.dart';
import 'package:overwatchapp/utils/native_messages.dart';
import 'package:overwatchapp/utils/print_debug.dart';

class StopMonitoring extends StatefulWidget {
  final String stopId;
  final String name;
  const StopMonitoring({super.key, required this.stopId, required this.name});

  @override
  State<StopMonitoring> createState() => _StopMonitoringState();
}

class _StopMonitoringState extends State<StopMonitoring> {
  String lastRefreshTime = '';
  String minutesUntilArrival = '';
  int currentTimerDuration = 60;
  int refreshCount = 0;
  FlutterTts tts = FlutterTts();
  late Timer? timer;

  Future<GetTransitStopArrivalTime> fetchArrivalTime() async {
    return appContainer.get<TransitApi>().fetchArrivalTime(widget.stopId);
  }

  Future<void> _refreshData(bool showNotification) async {
    GetTransitStopArrivalTime arrivalTime = await fetchArrivalTime();
    printForDebugging("Refreshing data...");

    minutesUntilArrival =
        arrivalTime.data.arrival?.minutesUntilArrival.toString() ?? 'N/A';
    lastRefreshTime = DateTime.now().toIso8601String();
    refreshCount++;

    var arrival = arrivalTime.data.arrival;

    if (arrival == null) {
      return;
    }

    var newTimerDuration = const Duration(minutes: 3);

    if (arrival.minutesUntilArrival < 3) {
      newTimerDuration = const Duration(seconds: 30);
    } else if (arrival.minutesUntilArrival < 5) {
      newTimerDuration = const Duration(minutes: 1);
    } else if (arrival.minutesUntilArrival < 7) {
      newTimerDuration = const Duration(minutes: 2);
    }

    String text;

    if (arrival.minutesUntilArrival == 0) {
      text = "Arriving now";
    } else {
      text =
          "Arrival in ${arrival.minutesUntilArrival} minute${arrival.minutesUntilArrival > 1 ? 's' : ''}";
    }

    tts.speak(text).catchError((err) {
      printForDebugging("Error speaking: $err");
    });

    sendNotification(CreateNativeNotification(
      title: widget.name,
      description: text,
    ));

    printForDebugging("setting to ${newTimerDuration.inSeconds}");

    setState(() {
      timer = Timer(newTimerDuration, () {
        _refreshData(true);
      });
      currentTimerDuration = newTimerDuration.inSeconds;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData(false);
  }

  @override
  void dispose() {
    super.dispose();

    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Stop ${widget.name}"),
        ),
        body: Column(
          children: [
            Text("Minutes until arrival: $minutesUntilArrival"),
            Text("Last refresh time: $lastRefreshTime"),
            Text("Refresh count: $refreshCount"),
          ],
        ));
  }
}
