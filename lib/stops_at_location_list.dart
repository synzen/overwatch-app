import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/route_stop.dart';
import 'package:overwatchapp/types/get_transit_stops_at_location.types.dart';
import 'package:overwatchapp/utils/app_container.dart';

class StopsAtLocationList extends StatefulWidget {
  const StopsAtLocationList({super.key});

  @override
  State<StopsAtLocationList> createState() => _StopsAtLocationListState();
}

class _StopsAtLocationListState extends State<StopsAtLocationList> {
  Future<GetTransitStopsAtLocation>? transitRoutes;
  late TextEditingController _searchController;
  bool _validate = false;

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
    transitRoutes =
        appContainer.get<TransitApi>().fetchTransitStopsAtLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void onSubmitSearch() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _validate = true;
      });

      return;
    }

    setState(() {
      _validate = false;
      transitRoutes =
          appContainer.get<TransitApi>().fetchTransitStopsAtLocation();
    });
  }

  void saveStopToCommute(BuildContext context, CommuteRouteRepository repo,
      String name, String stopId) {
    appContainer
        .get<CommuteRouteRepository>()
        .insert(CommuteRoute(name: name, stopIds: [stopId]))
        .then((route) {
      Navigator.of(context)
        ..pop()
        ..pop()
        ..pop();
    }).catchError((err) {
      if (err is DuplicateCommuteRouteException) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: const Text('Duplicate commute name'),
                  content: const Text(
                      'This name is already in use. Please choose another.'),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('OK'))
                  ],
                ));

        return;
      }

      throw err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transit routes at location'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          Row(children: [
            Flexible(
                child: TextField(
              autofocus: true,
              controller: _searchController,
              onChanged: (value) => setState(() {
                _validate = false;
              }),
              decoration: InputDecoration(
                hintText: 'Location',
                prefixIcon: const Icon(Icons.search),
                errorText: _validate ? 'Please enter a location' : null,
              ),
              onSubmitted: (value) {
                onSubmitSearch();
              },
            )),
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: () {
                onSubmitSearch();
              },
              child: const Text('Search'),
            ),
          ]),
          SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16),
              child: FutureBuilder<GetTransitStopsAtLocation>(
                future: transitRoutes,
                builder: (_, snapshot) {
                  if (transitRoutes == null) {
                    return const SizedBox();
                  }

                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        for (var route in snapshot.data!.data.routes)
                          Column(
                            children: [
                              Text(route.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              for (var grouping in route.groupings)
                                Column(
                                  children: [
                                    for (var stop in grouping.stops)
                                      RouteStop(
                                        stopId: stop.id,
                                        stopName: stop.name,
                                        stopDescription: grouping.name,
                                        popCount: 2,
                                      ),
                                  ],
                                ),
                            ],
                          ),
                      ],
                    );
                  } else if (snapshot.hasError) {
                    return const Text('Failed to load data');
                  }

                  return const CircularProgressIndicator();
                },
              ))
        ]),
      ),
    );
  }
}
