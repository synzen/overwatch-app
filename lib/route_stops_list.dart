import 'package:flutter/material.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/route_stop.dart';
import 'package:overwatchapp/types/get_transit_stop_for_route.types.dart';
import 'package:overwatchapp/utils/app_container.dart';

class RouteStopsList extends StatefulWidget {
  final String routeId;
  final String routeName;
  const RouteStopsList(
      {super.key, required this.routeId, required this.routeName});

  @override
  State<RouteStopsList> createState() => _RouteStopsListState();
}

class _RouteStopsListState extends State<RouteStopsList> {
  late Future<GetTransitStopsForRoute> stops;

  Future<GetTransitStopsForRoute> fetchStops() async {
    return appContainer.get<TransitApi>().fetchStops(widget.routeId);
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
                                ...group.stops.map((stop) => RouteStop(
                                      stopId: stop.id,
                                      stopName: stop.name,
                                      popCount: 3,
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
