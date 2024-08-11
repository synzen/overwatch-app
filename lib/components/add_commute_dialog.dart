import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:provider/provider.dart';

class AddCommuteDialog extends StatefulWidget {
  final HashMap<String, CommuteRouteStop> selectedStops;
  final Function() onSave;

  const AddCommuteDialog(
      {super.key, required this.selectedStops, required this.onSave});

  @override
  State<AddCommuteDialog> createState() => _AddCommuteDialogState();
}

class _AddCommuteDialogState extends State<AddCommuteDialog> {
  final TextEditingController _commuteNameController = TextEditingController();
  String? _errorText;

  void saveStopsToCommute(CommuteRouteRepository repo) {
    repo
        .insert(NewCommuteRoute(
            name: _commuteNameController.text,
            stops: widget.selectedStops.values.toList()))
        .then((_) {
      Navigator.of(context).pop();
      widget.onSave();
    }).catchError((err) {
      if (err is DuplicateCommuteRouteException) {
        setState(() {
          _errorText = 'This name is already in use. Please choose another.';
        });

        return;
      }

      throw err;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteRouteRepository>(
        builder: (context, repo, child) => Dialog(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Expanded(
                          child: Column(
                        children: [
                          TextField(
                            controller: _commuteNameController,
                            autofocus: true,
                            decoration: InputDecoration(
                                errorText: _errorText,
                                labelText: 'Name of commute'),
                            onSubmitted: (value) {
                              saveStopsToCommute(repo);
                            },
                          ),
                          Container(
                              margin: const EdgeInsets.only(top: 24),
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton(
                                    onPressed: () {
                                      saveStopsToCommute(repo);
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              ))
                        ],
                      )))
                ],
              ),
            ));
  }
}
