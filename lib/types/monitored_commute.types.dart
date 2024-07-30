import 'dart:convert';

class MonitoredCommute {
  final String name;
  final List<String> stopIds;

  const MonitoredCommute({required this.name, required this.stopIds});

  // to json
  String toJsonString() {
    return jsonEncode({
      'name': name,
      'stopIds': stopIds,
    });
  }

  // from json string
  factory MonitoredCommute.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return MonitoredCommute(
      name: json['name'],
      stopIds: List<String>.from(json['stopIds']),
    );
  }
}
