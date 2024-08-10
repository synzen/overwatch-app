import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:provider/provider.dart';

class AddCommmuteStopListItem extends StatefulWidget {
  final String stopId;
  final String stopName;
  final String routeId;
  final int popCount;
  final String? stopDescription;
  final Function(bool?) onChanged;
  final bool isChecked;

  const AddCommmuteStopListItem(
      {super.key,
      required this.stopId,
      required this.stopName,
      required this.popCount,
      required this.routeId,
      this.stopDescription,
      required this.isChecked,
      required this.onChanged});

  @override
  State<AddCommmuteStopListItem> createState() =>
      _AddCommmuteStopListItemState();
}

class _AddCommmuteStopListItemState extends State<AddCommmuteStopListItem> {
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
        .insert(CommuteRoute(name: _commuteNameController.text, stops: [
      CommuteRouteStop(
          id: widget.stopId,
          routeId: widget.routeId,
          routeName: widget.stopName)
    ]))
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
              CheckboxListTile(
                value: widget.isChecked,
                onChanged: widget.onChanged,
                title: Text(widget.stopName),
                subtitle: widget.stopDescription != null
                    ? Text(widget.stopDescription!)
                    : null,
              )
            ]));
  }
}
