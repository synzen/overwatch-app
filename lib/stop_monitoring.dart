import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:http/http.dart' as http;
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
  late Timer? timer = null;

  Future<GetTransitStopArrivalTime> fetchArrivalTime() async {
    try {
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:3000/transit-arrival-times?stop_id=${Uri.encodeComponent(widget.stopId)}'));

      if (response.statusCode == 200) {
        return GetTransitStopArrivalTime.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        printForDebugging(
            "Non-200 status code returned from server: ${response.statusCode}");
        throw Exception('Failed to load transit routes');
      }
    } catch (e) {
      printForDebugging("Error fetching transit routes: $e");

      rethrow;
    }
  }

  Future<void> _refreshData() async {
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

    tts.speak("Arrival in ${arrival.minutesUntilArrival} minutes");

    printForDebugging("setting to ${newTimerDuration.inSeconds}");

    setState(() {
      timer = Timer(newTimerDuration, () {
        _refreshData();
      });
      currentTimerDuration = newTimerDuration.inSeconds;
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshData();
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
