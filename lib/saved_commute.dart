import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:provider/provider.dart';

class SavedCommute extends StatefulWidget {
  final List<CommuteRouteStop> stops;
  final String name;
  const SavedCommute({super.key, required this.stops, required this.name});

  @override
  State<SavedCommute> createState() => _SavedCommuteState();
}

class _SavedCommuteState extends State<SavedCommute> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteMonitoringService>(
        builder: (context, service, child) => ListTile(
              title: Text(widget.name),
              onTap: () {
                service.startMonitoring(widget.name,
                    widget.stops.map((s) => s.id).toSet().toList());
              },
            ));
  }
}
