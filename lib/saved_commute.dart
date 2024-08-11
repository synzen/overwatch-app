import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:overwatchapp/components/confirm_delete_commute_dialog.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:provider/provider.dart';

class SavedCommute extends StatefulWidget {
  final int commuteId;
  final List<CommuteRouteStop> stops;
  final String name;
  const SavedCommute(
      {super.key,
      required this.commuteId,
      required this.stops,
      required this.name});

  @override
  State<SavedCommute> createState() => _SavedCommuteState();
}

class _SavedCommuteState extends State<SavedCommute> {
  bool isExpanded = false;
  // include all initial stop hash keys
  final HashSet<String> selectedStops = HashSet();

  @override
  void initState() {
    super.initState();

    for (var stop in widget.stops) {
      selectedStops.add(stop.hashKey);
    }
  }

  void onClickTile() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  void onCheckedStop(CommuteRouteStop stop) {
    setState(() {
      if (selectedStops.contains(stop.hashKey)) {
        selectedStops.remove(stop.hashKey);
      } else {
        selectedStops.add(stop.hashKey);
      }
    });
  }

  void onClickStartMonitoring(CommuteMonitoringService service) {
    service.startMonitoring(
        widget.name,
        widget.stops.where((stop) {
          return selectedStops.contains(stop.hashKey);
        }).toList());

    setState(() {
      isExpanded = false;
    });
  }

  void onClickDelete(BuildContext context) {
    // show alert to confirm
    showDialog(
        context: context,
        builder: (context) => ConfirmDeleteCommuteDialog(
              commuteId: widget.commuteId,
              onDeleted: () {
                Navigator.of(context).pop();
              },
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteMonitoringService>(
        builder: (context, service, child) => Column(children: [
              Container(
                  color: isExpanded
                      ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                      : null,
                  child: ListTile(
                    title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(widget.name, maxLines: 1),
                          // expand icon
                          Icon(isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more)
                        ]),
                    onTap: () {
                      onClickTile();
                    },
                  )),
              if (isExpanded)
                Container(
                    decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        border: Border(
                            left: BorderSide(
                                width: 4,
                                color: Theme.of(context).colorScheme.primary))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            margin: const EdgeInsets.only(
                                left: 16, top: 8, bottom: 8),
                            child: Text('Routes',
                                style:
                                    Theme.of(context).textTheme.labelMedium)),
                        for (var stop in widget.stops)
                          CheckboxListTile(
                            title: Text(
                              stop.routeName,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            value: selectedStops.contains(stop.hashKey),
                            onChanged: (value) => onCheckedStop(stop),
                          ),
                        Container(
                            alignment: Alignment.centerRight,
                            margin: const EdgeInsets.only(
                                left: 16, right: 16, bottom: 16, top: 8),
                            child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  OutlinedButton(
                                      // error themed
                                      style: ButtonStyle(
                                          foregroundColor:
                                              WidgetStateProperty.all(
                                                  Theme.of(context)
                                                      .colorScheme
                                                      .error)),
                                      onPressed: () {
                                        onClickDelete(context);
                                      },
                                      child: const Text("Delete")),
                                  FilledButton(
                                      onPressed: () {
                                        onClickStartMonitoring(service);
                                      },
                                      child: const Text("Start Monitoring"))
                                ])),
                      ],
                    ))
            ]));
  }
}
