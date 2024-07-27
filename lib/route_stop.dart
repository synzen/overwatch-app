import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:provider/provider.dart';

class RouteStop extends StatefulWidget {
  final String stopId;
  final String stopName;
  final int popCount;
  final String? stopDescription;
  const RouteStop(
      {super.key,
      required this.stopId,
      required this.stopName,
      required this.popCount,
      this.stopDescription});

  @override
  State<RouteStop> createState() => _RouteStopState();
}

class _RouteStopState extends State<RouteStop> {
  late TextEditingController _commuteNameController;

  @override
  void reassemble() {
    super.reassemble();
    setState(() {
      _commuteNameController = TextEditingController();
    });
  }

  @override
  void initState() {
    super.initState();
    _commuteNameController = TextEditingController();
  }

  @override
  void dispose() {
    _commuteNameController.dispose();
    super.dispose();
  }

  void saveStopToCommute(BuildContext context, CommuteRouteRepository repo) {
    repo
        .insert(CommuteRoute(
            name: _commuteNameController.text, stopIds: [widget.stopId]))
        .then((route) {
      for (int i = 0; i < widget.popCount; i++) {
        Navigator.of(context).pop();
      }
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
    return Consumer<CommuteRouteRepository>(
        builder: (context, commuteRepository, child) => Column(children: [
              ListTile(
                  title: Text(widget.stopName),
                  subtitle: widget.stopDescription != null
                      ? Text(widget.stopDescription!)
                      : null,
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) => Dialog(
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
                                            decoration: const InputDecoration(
                                                labelText: 'Name of commute'),
                                            onSubmitted: (value) {
                                              saveStopToCommute(
                                                  context, commuteRepository);
                                            },
                                          ),
                                          Container(
                                              margin: const EdgeInsets.only(
                                                  top: 24),
                                              alignment: Alignment.centerRight,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text('Cancel'),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  FilledButton(
                                                    onPressed: () {
                                                      saveStopToCommute(context,
                                                          commuteRepository);
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
                  })
            ]));
  }
}
