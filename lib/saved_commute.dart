import 'package:flutter/material.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:provider/provider.dart';

class SavedCommute extends StatefulWidget {
  final String stopId;
  final String name;
  const SavedCommute({super.key, required this.stopId, required this.name});

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
                service.startMonitoring(widget.name, [widget.stopId]);
              },
            ));
  }
}
