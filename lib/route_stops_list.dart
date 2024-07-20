import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:overwatchapp/types/get_transit_stop_for_route.types.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    try {
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:3000/transit-stops-for-route?route_id=${widget.routeId}'));

      if (response.statusCode == 200) {
        return GetTransitStopsForRoute.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        if (kDebugMode) {
          debugPrint(
              "Non-200 status code returned from server: ${response.statusCode}");
        }
        throw Exception('Failed to load transit routes');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching transit routes: $e");
      }

      rethrow;
    }
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
                return const CircularProgressIndicator();
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

class RouteStop extends StatelessWidget {
  final String stopId;
  final String stopName;
  const RouteStop({super.key, required this.stopId, required this.stopName});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(stopName),
      onTap: () {
        Navigator.of(context).pop();
      },
    );
  }
}
