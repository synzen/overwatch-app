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
  Future<GetTransitRoutesResponse>? transitRoutes;
  late TextEditingController _searchController;

  Future<GetTransitRoutesResponse> fetchTransitRoutes(String search) async {
    if (search.isEmpty) {
      throw Exception('Search query cannot be empty');
    }

    try {
      final response = await http.get(Uri.parse(
          'http://10.0.2.2:3000/transit-routes?search=${Uri.encodeComponent(search)}'));

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
      _searchController = TextEditingController();
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit Routes'),
      ),
      body: Container(
        margin: const EdgeInsets.all(16.0),
        alignment: Alignment.center,
        child: Column(children: [
          Row(children: [
            Flexible(
                child: TextField(
              autofocus: true,
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Bus name',
                prefixIcon: Icon(Icons.search),
              ),
              onSubmitted: (value) {
                if (value.isEmpty) {
                  return;
                }

                setState(() {
                  transitRoutes = fetchTransitRoutes(value);
                });
              },
            )),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                if (_searchController.text.isEmpty) {
                  return;
                }

                setState(() {
                  transitRoutes = fetchTransitRoutes(_searchController.text);
                });
              },
              child: const Text('Search'),
            ),
          ]),
          SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16),
              child: FutureBuilder<GetTransitRoutesResponse>(
                future: transitRoutes,
                builder: (_, snapshot) {
                  if (_searchController.text == '') {
                    return const Text('Enter a bus name to search');
                  }

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
              ))
        ]),
      ),
    );
  }
}
