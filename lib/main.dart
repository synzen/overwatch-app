import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/pages/add_stop/add_commute.dart';
import 'package:overwatchapp/saved_commute.dart';
import 'package:overwatchapp/services/commute_monitoring.service.dart';
import 'package:overwatchapp/utils/app_container.dart';
import 'package:overwatchapp/utils/native_messages.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:overwatchapp/utils/theme.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:overwatchapp/components/monitored_commute_alert.dart';

const prod = bool.fromEnvironment('dart.vm.product');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNativeMessaging();

  printForDebugging('Initializing database');
  final dbPath = join(await getDatabasesPath(), 'overwatch_db.db');
  await deleteDatabase(dbPath);
  final database = openDatabase(dbPath, onCreate: (db, version) async {
    await db.execute(
      """
      CREATE TABLE commute_routes(
          id integer primary key,
          name    text unique not null
      );
      """,
    );

    await db.execute("""
      CREATE TABLE commute_route_stops(
        id integer primary key,
        commute_id integer not null,
        stop_id text not null,
        route_id text not null,
        route_name text not null,
        FOREIGN KEY (commute_id) REFERENCES commute_routes(id) ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED
      );
      """);
  }, onConfigure: (Database db) async {
    await db.execute("PRAGMA foreign_keys = ON");
  }, version: 1);

  printForDebugging('Running app');

  await dotenv.load(fileName: prod ? '.env.prod' : '.env');

  FlutterForegroundTask.initCommunicationPort();

  appContainer
      .register<TransitApi>(TransitApi.fromEnv())
      .register<FlutterTts>(FlutterTts());

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
        create: (context) => CommuteRouteRepository(database)),
    ChangeNotifierProvider(create: (context) => CommuteMonitoringService()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const String appTitle = 'Overwatch';
    final brightness = View.of(context).platformDispatcher.platformBrightness;

    TextTheme textTheme = createTextTheme(context, "Ubuntu", "Ubuntu");

    MaterialTheme theme = MaterialTheme(textTheme);

    return MaterialApp(
      title: appTitle,
      theme: brightness == Brightness.light ? theme.light() : theme.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        floatingActionButton: const AddStopButton(),
        body: SingleChildScrollView(
          child: Column(
            children: [
              const SavedRoutesList(),
              // random button
              ElevatedButton(
                onPressed: () async {
                  printForDebugging('Random button pressed');

                  try {
                    final player = AudioPlayer();
                    await player.setUrl("http://10.0.2.2:3000/audio");
                    await player.play();
                  } catch (e) {
                    printForDebugging('Error playing audio: $e');
                  }
                },
                child: const Text('Play sound'),
              ),
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
  late Future<void> currentlyMonitoring;

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteRouteRepository>(
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MonitoredCommuteAlert(),
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
                                  name: commute.name, stops: commute.stops))
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
            MaterialPageRoute(
              builder: (context) => const AddCommutePage(),
            ));
      },
      child: const Icon(Icons.add),
    );
  }
}
