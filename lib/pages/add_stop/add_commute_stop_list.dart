import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_stop_list_item.dart';
import 'package:overwatchapp/types/get_transit_stops_at_location.types.dart';
import 'package:overwatchapp/utils/app_container.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:permission_handler/permission_handler.dart';

class AddCommuteStopList extends StatefulWidget {
  final void Function(CommuteRouteStop) onStopAdded;
  final void Function(CommuteRouteStop) onStopRemoved;
  final bool Function(CommuteRouteStop) isStopSelected;
  const AddCommuteStopList(
      {super.key,
      required this.onStopAdded,
      required this.onStopRemoved,
      required this.isStopSelected});

  @override
  State<AddCommuteStopList> createState() => _StopsAtLocationListState();
}

class _StopsAtLocationListState extends State<AddCommuteStopList> {
  Future<GetTransitStopsAtLocation>? transitRoutes;
  GetTransitStopsAtLocation? _cachedTransitStops;
  bool refetching = false;

  Future<void> fetchData({promptForPermission = false}) async {
    var future = appContainer.get<TransitApi>().fetchTransitStopsAtLocation(
        promptForLocationPermission: promptForPermission);
    setState(() {
      transitRoutes = future;
    });

    var data = await future;

    if (mounted) {
      setState(() {
        _cachedTransitStops = data;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (_cachedTransitStops == null) {
      fetchData();
    } else {
      setState(() {
        transitRoutes = Future.value(_cachedTransitStops);
      });
    }
  }

  void onClickTryAgain() async {
    setState(() {
      refetching = true;
    });

    await fetchData(promptForPermission: true);

    setState(() {
      refetching = false;
    });
  }

  void onClickOpenAppSettings() {
    openAppSettings();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(children: [
        if (transitRoutes == null)
          const Text('Enter a location to search for transit routes'),
        SingleChildScrollView(
            child: FutureBuilder<GetTransitStopsAtLocation>(
          future: transitRoutes,
          builder: (_, snapshot) {
            if (transitRoutes == null) {
              return const SizedBox();
            }

            if (snapshot.hasError) {
              printForDebugging(
                  "Failed to get stops at location: ${snapshot.error}");
              return Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                  ),
                  child: Column(children: [
                    const Text(
                        'Failed to get stops at location. Please try again.'),
                    Container(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(top: 16),
                        child: FilledButton(
                            onPressed: refetching
                                ? null
                                : () {
                                    onClickTryAgain();
                                  },
                            child: refetching
                                ? const CircularProgressIndicator()
                                : const Text('Try again'))),
                  ]));
            }

            return Column(
              children: [
                // Alert container about inaccuracy
                if (snapshot.hasData && snapshot.data!.isHighAccuracy == false)
                  Column(children: [
                    Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.1),
                          ),
                          child: Column(children: [
                            const Text(
                                'Stops were found with a low level of accuracy. You may try again, or enable more precise location access in the app settings'),
                            // button to re-request permissiion
                            Container(
                                alignment: Alignment.centerLeft,
                                margin: const EdgeInsets.only(top: 8),
                                child:
                                    Flex(direction: Axis.horizontal, children: [
                                  FilledButton(
                                      onPressed: refetching
                                          ? null
                                          : () {
                                              onClickTryAgain();
                                            },
                                      child: const Text('Try again')),
                                  const SizedBox(width: 8),
                                  TextButton(
                                      onPressed: onClickOpenAppSettings,
                                      child: refetching
                                          ? const CircularProgressIndicator()
                                          : const Text('Open app settings'))
                                ])),
                          ]),
                        )),
                  ]),

                if (snapshot.connectionState == ConnectionState.active ||
                    snapshot.connectionState == ConnectionState.waiting)
                  Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(child: CircularProgressIndicator())),

                if (!refetching && snapshot.hasData)
                  for (final route in snapshot.data!.data.routes)
                    Column(
                      children: [
                        Container(
                            padding: const EdgeInsets.all(16),
                            alignment: Alignment.centerLeft,
                            child: Text(route.name,
                                textAlign: TextAlign.left,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18))),
                        for (final grouping in route.groupings)
                          Column(
                            children: [
                              for (final stop in grouping.stops)
                                AddCommmuteStopListItem(
                                  stopId: stop.id,
                                  stopName: stop.name,
                                  stopDescription: grouping.name,
                                  routeId: route.id,
                                  popCount: 2,
                                  onChanged: (v) {
                                    if (v == null) {
                                      return;
                                    }

                                    final commuteRouteStop = CommuteRouteStop(
                                        id: stop.id,
                                        routeId: route.id,
                                        routeName: route.name);

                                    if (v) {
                                      widget.onStopAdded(commuteRouteStop);
                                    } else {
                                      widget.onStopRemoved(commuteRouteStop);
                                    }
                                  },
                                  isChecked: widget.isStopSelected(
                                      CommuteRouteStop(
                                          id: stop.id,
                                          routeId: route.id,
                                          routeName: route.name)),
                                ),
                            ],
                          ),
                      ],
                    ),
              ],
            );
          },
        ))
      ]),
    );
  }
}
