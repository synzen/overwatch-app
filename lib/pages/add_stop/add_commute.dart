import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:overwatchapp/components/add_commute_dialog.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_routes_list.dart';
import 'package:overwatchapp/pages/add_stop/add_commute_stop_list.dart';

class AddCommutePage extends StatefulWidget {
  const AddCommutePage({super.key});

  @override
  State<AddCommutePage> createState() => _AddCommutePageState();
}

class _AddCommutePageState extends State<AddCommutePage> {
  final HashSet<String> _selectedStops = HashSet();

  void onStopAdded(String stopId) {
    setState(() {
      _selectedStops.add(stopId);
    });
  }

  void onStopRemoved(String stopId) {
    setState(() {
      _selectedStops.remove(stopId);
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
                selectedStops: _selectedStops,
              ),
              const AddCommuteRoutesList(),
            ],
          ),
        ));
  }
}
