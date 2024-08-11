import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:provider/provider.dart';

class ConfirmDeleteCommuteDialog extends StatefulWidget {
  final int commuteId;
  final Function() onDeleted;

  const ConfirmDeleteCommuteDialog(
      {super.key, required this.commuteId, required this.onDeleted});

  @override
  State<ConfirmDeleteCommuteDialog> createState() =>
      _ConfirmDeleteCommuteDialogState();
}

class _ConfirmDeleteCommuteDialogState
    extends State<ConfirmDeleteCommuteDialog> {
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
                          const Text(
                              'Are you sure you want to delete this commute?'),
                          const SizedBox(
                            height: 16,
                          ),
                          Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel')),
                                TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: Theme.of(context)
                                            .colorScheme
                                            .error),
                                    onPressed: () {
                                      repo.delete(widget.commuteId).then((_) {
                                        widget.onDeleted();
                                      });
                                    },
                                    child: const Text('Delete')),
                              ]),
                        ],
                      )))
                ],
              ),
            ));
  }
}
