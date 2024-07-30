import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:overwatchapp/components/loader.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:overwatchapp/types/monitored_commute.types.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:provider/provider.dart';

class MonitoredCommuteAlert extends StatefulWidget {
  const MonitoredCommuteAlert({super.key});

  @override
  State<MonitoredCommuteAlert> createState() => _MonitoredCommuteAlertState();
}

class _MonitoredCommuteAlertState extends State<MonitoredCommuteAlert> {
  late Future<MonitoredCommute?> _monitoredCommute;

  @override
  void initState() {
    super.initState();
    setState(() {
      _monitoredCommute =
          FlutterForegroundTask.isRunningService.then((isRunning) {
        if (isRunning) {
          printForDebugging('RUNNING: Getting monitored commute');
          return FlutterForegroundTask.getData<String>(key: "commute");
        } else {
          printForDebugging('NOT RUNNING: No monitored commute');
          return Future.value(null);
        }
      }).then((v) {
        if (v != null) {
          return MonitoredCommute.fromJsonString(v);
        } else {
          return null;
        }
      });
    });
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      _monitoredCommute =
          FlutterForegroundTask.isRunningService.then((isRunning) {
        if (isRunning) {
          printForDebugging('RUNNING: Getting monitored commute');
          return FlutterForegroundTask.getData<String>(key: "commute");
        } else {
          printForDebugging('NOT RUNNING: No monitored commute');
          return Future.value(null);
        }
      }).then((v) {
        // printForDebugging('Monitored commute: $v');
        if (v != null) {
          return MonitoredCommute.fromJsonString(v);
        } else {
          return null;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteMonitoringService>(
        builder: (context, service, child) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (service.monitoredCommute != null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.secondary),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Currently monitoring commute...",
                            textAlign: TextAlign.left,
                            style: TextStyle(
                                color:
                                    Theme.of(context).colorScheme.onSecondary),
                          ),
                          Text(service.monitoredCommute!.name,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24)),
                          if (service.estimateText != null)
                            Text(
                              service.estimateText ?? '',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 18),
                            ),
                          Container(
                              margin: const EdgeInsets.only(top: 16),
                              child: FilledButton.tonal(
                                  onPressed: () {
                                    service.stopMonitoring();
                                  },
                                  child: const Text(
                                    'Stop monitoring',
                                  )))
                        ]),
                  )
              ],
            ));
  }
}
