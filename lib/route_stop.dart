import 'package:flutter/material.dart';

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
