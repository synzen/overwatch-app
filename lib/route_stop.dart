import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:provider/provider.dart';

class RouteStop extends StatelessWidget {
  final String stopId;
  final String stopName;
  const RouteStop({super.key, required this.stopId, required this.stopName});

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteRouteRepository>(
        builder: (context, commuteRepository, child) => Column(children: [
              ListTile(
                  title: Text(stopName),
                  onTap: () {
                    commuteRepository
                        .insert(CommuteRoute(name: stopName, stopIds: [stopId]))
                        .then((route) {
                      Navigator.of(context)
                        ..pop()
                        ..pop();
                    });
                  })
            ]));
  }
}
