import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:overwatchapp/route_stops_list.dart';
import 'package:overwatchapp/types/get_transit_routes.types.dart';
import 'package:http/http.dart' as http;

class RoutesList extends StatefulWidget {
  const RoutesList({super.key});

  @override
  State<RoutesList> createState() => _RoutesListState();
}

class _RoutesListState extends State<RoutesList> {
  late Future<GetTransitRoutesResponse> transitRoutes;

  Future<GetTransitRoutesResponse> fetchTransitRoutes() async {
    try {
      final response = await http
          .get(Uri.parse('http://10.0.2.2:3000/transit-routes?search=b2'));

      if (response.statusCode == 200) {
        return GetTransitRoutesResponse.fromJson(
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
      transitRoutes = fetchTransitRoutes();
    });
  }

  @override
  void initState() {
    super.initState();
    transitRoutes = fetchTransitRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Transit Routes'),
        ),
        body: Column(children: [
          FutureBuilder<GetTransitRoutesResponse>(
            future: transitRoutes,
            builder: (_, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: snapshot.data?.data.routes
                          .map((route) => ListTile(
                              title: Text(route.name),
                              subtitle: Text(route.id),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => RouteStopsList(
                                      routeId: route.id,
                                      routeName: route.name,
                                    ),
                                  ),
                                );
                              }))
                          .toList() ??
                      [],
                );
              } else if (snapshot.hasError) {
                return const Text('Failed to load transit routes');
              }

              return const CircularProgressIndicator();
            },
          ),
        ]));
  }
}
