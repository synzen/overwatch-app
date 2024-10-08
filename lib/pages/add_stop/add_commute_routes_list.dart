import 'package:flutter/material.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_routes_list_item.dart';
import 'package:overwatchapp/types/get_transit_routes.types.dart';
import 'package:overwatchapp/utils/app_container.dart';

class AddCommuteRoutesList extends StatefulWidget {
  const AddCommuteRoutesList({super.key});

  @override
  State<AddCommuteRoutesList> createState() => _AddCommuteRoutesListState();
}

class _AddCommuteRoutesListState extends State<AddCommuteRoutesList> {
  Future<GetTransitRoutesResponse>? transitRoutes;
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

    if (_searchController.text.isEmpty) {
      return;
    }

    setState(() {
      _validate = false;
      transitRoutes = appContainer
          .get<TransitApi>()
          .fetchTransitRoutes(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
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
              hintText: 'Bus name',
              prefixIcon: const Icon(Icons.search),
              errorText: _validate ? 'Please enter a bus name' : null,
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
            child: FutureBuilder<GetTransitRoutesResponse>(
              future: transitRoutes,
              builder: (_, snapshot) {
                if (transitRoutes == null) {
                  return const SizedBox();
                }

                if (snapshot.hasData) {
                  return Column(
                    children: snapshot.data?.data.routes
                            .map((route) => ListTile(
                                title: Text(route.name),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          AddCommuteRoutesListItem(
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
    );
  }
}
