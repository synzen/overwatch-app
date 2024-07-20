import 'package:flutter/material.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/routes_list.dart';
import 'package:overwatchapp/saved_commute.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  printForDebugging('Initializing database');
  final dbPath = join(await getDatabasesPath(), 'overwatch_db.db');
  await deleteDatabase(dbPath);
  final database = openDatabase(dbPath, onCreate: (db, version) async {
    await db.execute(
      """
      CREATE TABLE commute_routes(
          id integer primary key,
          name    text
      );
      """,
    );

    await db.execute("""
      CREATE TABLE commute_route_stops(
        id integer primary key,
        route_id integer,
        stop_id text,
        FOREIGN KEY (route_id) REFERENCES commute_routes(id) ON DELETE CASCADE
      );
      """);
  }, onConfigure: (Database db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  }, version: 1);

  printForDebugging('Running app');
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
        create: (context) => CommuteRouteRepository(database))
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Overwatch';
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        floatingActionButton: const AddStopButton(),
        body: const SingleChildScrollView(
          child: Column(
            children: [
              SavedRoutesList(),
            ],
          ),
        ),
      ),
    );
  }
}

class SavedRoutesList extends StatefulWidget {
  const SavedRoutesList({super.key});

  @override
  State<SavedRoutesList> createState() => _SavedRoutesListState();
}

class _SavedRoutesListState extends State<SavedRoutesList> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteRouteRepository>(
        child: const Column(
          children: [
            Text('Commutes', textScaler: TextScaler.linear(1.5)),
          ],
        ),
        builder: (context, commuteRepository, child) => Column(
              children: [
                FutureBuilder(
                    future: commuteRepository.get(),
                    builder: (_, snapshot) {
                      if (snapshot.hasError) {
                        return const Text('Error loading commutes');
                      }

                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }

                      final components = snapshot.data
                              ?.map((commute) => SavedCommute(
                                  name: commute.name,
                                  stopId: commute.stopIds[0]))
                              .toList() ??
                          [];

                      return Column(
                        children: [
                          if (child != null) child,
                          ...components,
                        ],
                      );
                    })
              ],
            ));
  }
}

class AddStopButton extends StatelessWidget {
  const AddStopButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RoutesList()),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
