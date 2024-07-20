import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:overwatchapp/stop_monitoring.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:http/http.dart' as http;

class SavedRouteStop extends StatefulWidget {
  final String stopId;
  final String name;
  const SavedRouteStop({super.key, required this.stopId, required this.name});

  @override
  State<SavedRouteStop> createState() => _SavedRouteStopState();
}

class _SavedRouteStopState extends State<SavedRouteStop> {
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
    return ListTile(
      title: Text(widget.name),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StopMonitoring(
              stopId: widget.stopId,
              name: widget.name,
            ),
          ),
        );
      },
    );
  }
}
