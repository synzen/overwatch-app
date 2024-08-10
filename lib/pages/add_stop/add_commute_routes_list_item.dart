import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:overwatchapp/components/add_commute_dialog.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_stop_list_item.dart';
import 'package:overwatchapp/types/get_transit_stop_for_route.types.dart';
import 'package:overwatchapp/utils/app_container.dart';

class AddCommuteRoutesListItem extends StatefulWidget {
  final String routeId;
  final String routeName;
  const AddCommuteRoutesListItem(
      {super.key, required this.routeId, required this.routeName});

  @override
  State<AddCommuteRoutesListItem> createState() =>
      _AddCommuteRoutesListItemState();
}

class _AddCommuteRoutesListItemState extends State<AddCommuteRoutesListItem> {
  late Future<GetTransitStopsForRoute> stops;
  final HashMap<String, CommuteRouteStop> _selectedStops = HashMap();

  Future<GetTransitStopsForRoute> fetchStops() async {
    return appContainer.get<TransitApi>().fetchStops(widget.routeId);
  }

  void onStopAdded(CommuteRouteStop stop) {
    setState(() {
      _selectedStops[stop.hashKey] = stop;
    });
  }

  void onStopRemoved(CommuteRouteStop stop) {
    setState(() {
      _selectedStops.remove(stop.hashKey);
    });
  }

  bool isStopSelected(CommuteRouteStop stop) {
    return _selectedStops.containsKey(stop.hashKey);
  }

  void onClickAdd(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AddCommuteDialog(
            selectedStops: _selectedStops,
            onSave: () {
              Navigator.of(context)
                ..pop()
                ..pop();
            }));
  }

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      stops = fetchStops();
    });
  }

  @override
  void initState() {
    super.initState();
    stops = fetchStops();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Route ${widget.routeName}'),
          actions: [
            Container(
                margin: const EdgeInsets.only(right: 16),
                child: FilledButton(
                  onPressed: _selectedStops.isEmpty
                      ? null
                      : () {
                          onClickAdd(context);
                        },
                  child: const Text("Add"),
                )),
          ],
        ),
        body: SingleChildScrollView(
          child: FutureBuilder<GetTransitStopsForRoute>(
            future: stops,
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return const Text('Failed to load transit stops');
              }

              if (!snapshot.hasData) {
                return Container(
                    padding: const EdgeInsets.all(32),
                    child: const Center(child: CircularProgressIndicator()));
              }

              return Column(
                children: snapshot.data?.data.groups
                        .map((group) => Column(
                              children: [
                                Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      group.name,
                                      textScaler: const TextScaler.linear(1.5),
                                    )),
                                ...group.stops
                                    .map((stop) => AddCommmuteStopListItem(
                                          stopId: stop.id,
                                          stopName: stop.name,
                                          routeId: widget.routeId,
                                          popCount: 3,
                                          isChecked: isStopSelected(
                                              CommuteRouteStop(
                                                  id: stop.id,
                                                  routeId: widget.routeId)),
                                          onChanged: (v) {
                                            if (v == null) {
                                              return;
                                            }

                                            final commuteRouteStop =
                                                CommuteRouteStop(
                                                    id: stop.id,
                                                    routeId: widget.routeId);

                                            if (v) {
                                              onStopAdded(commuteRouteStop);
                                            } else {
                                              onStopRemoved(commuteRouteStop);
                                            }
                                          },
                                        )),
                                // ),
                              ],
                            ))
                        .toList() ??
                    [],
              );
            },
          ),
        ));
  }
}
