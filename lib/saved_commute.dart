import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class SavedCommute extends StatefulWidget {
  final String stopId;
  final String name;
  const SavedCommute({super.key, required this.stopId, required this.name});

  @override
  State<SavedCommute> createState() => _SavedCommuteState();
}

class _SavedCommuteState extends State<SavedCommute> {
  Future<GetTransitStopArrivalTime> fetchStops() async {
    try {
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:3000/transit-arrival-times?stop_id=${Uri.encodeComponent(widget.stopId)}'));

      if (response.statusCode == 200) {
        return GetTransitStopArrivalTime.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        if (kDebugMode) {
          debugPrint(
              "Non-200 status code returned from server: ${response.statusCode}");
        }
        throw Exception('Failed to load transit routes');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching transit routes: $e");
      }

      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteMonitoringService>(
        builder: (context, service, child) => ListTile(
              title: Text(widget.name),
              onTap: () {
                service.startMonitoring(widget.name, [widget.stopId]);
              },
            ));
  }
}
