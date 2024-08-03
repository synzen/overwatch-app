import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:overwatchapp/components/add_commute_dialog.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_routes_list.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_stop_list.dart';

class AddCommutePage extends StatefulWidget {
  const AddCommutePage({super.key});

  @override
  State<AddCommutePage> createState() => _AddCommutePageState();
}

class _AddCommutePageState extends State<AddCommutePage> {
  final HashMap<String, CommuteRouteStop> _selectedStops = HashMap();

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

  void onClickAdd(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) => AddCommuteDialog(
            selectedStops: _selectedStops,
            onSave: () {
              Navigator.of(context).pop();
            }));
  }

  bool isStopSelected(CommuteRouteStop stop) {
    return _selectedStops.containsKey(stop.hashKey);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Add Commute'),
            actions: [
              // add stops button
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
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Nearby'),
                Tab(text: 'Search'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              AddCommuteStopList(
                onStopAdded: onStopAdded,
                onStopRemoved: onStopRemoved,
                isStopSelected: isStopSelected,
              ),
              const AddCommuteRoutesList(),
            ],
          ),
        ));
  }
}
