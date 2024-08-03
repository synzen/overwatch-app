import 'package:flutter/material.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:provider/provider.dart';

class MonitoredCommuteAlert extends StatefulWidget {
  const MonitoredCommuteAlert({super.key});

  @override
  State<MonitoredCommuteAlert> createState() => _MonitoredCommuteAlertState();
}

class _MonitoredCommuteAlertState extends State<MonitoredCommuteAlert> {
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
                          Text(service.monitoredCommute!.name,
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24)),
                          const SizedBox(
                            height: 8,
                          ),
                          if (service.arrivalTimes != null)
                            Text(
                              service.arrivalTimes!.data.arrivals.isNotEmpty
                                  ? "${service.arrivalTimes!.data.arrivals.first.routeLabel} in ${service.arrivalTimes!.data.arrivals.first.minutesUntilArrival} minutes"
                                  : "No arrivals found",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 18),
                            ),
                          if (service.arrivalTimes == null)
                            Text(
                              "Locating arrivals...",
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onSecondary,
                                  fontSize: 18),
                            ),
                          if (service.arrivalTimes != null &&
                              service.arrivalTimes!.data.arrivals.isNotEmpty)
                            Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 4,
                                  ),
                                  for (final arrival in service
                                      .arrivalTimes!.data.arrivals
                                      .sublist(1))
                                    Text(
                                      '${arrival.routeLabel} in ${arrival.minutesUntilArrival} minutes',
                                      style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondary,
                                          fontSize: 14),
                                    )
                                ]),
                          Container(
                              margin: const EdgeInsets.only(top: 12),
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
