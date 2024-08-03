import 'dart:convert';
import 'package:overwatchapp/data/commute_route.repository.dart';

class MonitoredCommute {
  final String name;
  final List<CommuteRouteStop> stops;

  const MonitoredCommute({required this.name, required this.stops});

  // to json
  String toJsonString() {
    return jsonEncode({
      'name': name,
      'stops': stops.map((stop) => stop.toJson()).toList(),
    });
  }

  // from json string
  factory MonitoredCommute.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    return MonitoredCommute(
      name: json['name'],
      stops: (json['stops'] as List<dynamic>)
          .map((stop) => CommuteRouteStop.fromJson(stop))
          .toList(),
    );
  }
}
