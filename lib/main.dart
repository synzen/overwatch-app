import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:just_audio/just_audio.dart';
import 'package:overwatchapp/data/commute_route.repository.dart';
import 'package:overwatchapp/data/geo_service.dart';
import 'package:overwatchapp/data/transit_api.dart';
import 'package:overwatchapp/routes_list.dart';
import 'package:overwatchapp/saved_commute.dart';
import 'package:overwatchapp/stops_at_location_list.dart';
import 'package:overwatchapp/utils/app_container.dart';
import 'package:overwatchapp/utils/native_messages.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:overwatchapp/utils/theme.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const prod = bool.fromEnvironment('dart.vm.product');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeNativeMessaging();

  printForDebugging('Initializing database');
  final dbPath = join(await getDatabasesPath(), 'overwatch_db.db');
  // await deleteDatabase(dbPath);
  final database = openDatabase(dbPath, onCreate: (db, version) async {
    await db.execute(
      """
      CREATE TABLE commute_routes(
          id integer primary key,
          name    text unique
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

  await dotenv.load(fileName: prod ? '.env.prod' : '.env');

  var apiUrl = dotenv.env['API_URL'];
  var apiKey = dotenv.env['API_KEY'];

  if (apiUrl == null || apiKey == null) {
    throw Exception('API_URL and API_KEY must be set in .env file');
  }

  FlutterForegroundTask.initCommunicationPort();

  GeoService geoService = GeoService();
  appContainer.register<TransitApi>(
      TransitApi(baseUrl: apiUrl, apiKey: apiKey, geoService: geoService));

  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(
        create: (context) => CommuteRouteRepository(database)),
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
  Future<void> _sendNotification() async {
    try {
      await sendNotification(const CreateNativeNotification(
          description: "some description", title: 'My Title'));
    } on PlatformException catch (e) {
      printForDebugging('Error sending notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CommuteRouteRepository>(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _sendNotification,
              child: const Text('Create notification'),
            ),
            const Text('Commutes', textScaler: TextScaler.linear(1.5)),
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
          MaterialPageRoute(
              builder: (context) => DefaultTabController(
                  length: 2,
                  child: Scaffold(
                    appBar: AppBar(
                      title: const Text('Add Commute'),
                      bottom: const TabBar(
                        tabs: [
                          Tab(text: 'Nearby'),
                          Tab(text: 'Search'),
                        ],
                      ),
                    ),
                    body: const TabBarView(
                      children: [
                        StopsAtLocationList(),
                        RoutesList(),
                      ],
                    ),
                  ))),
        );
      },
      child: const Icon(Icons.add),
    );
  }
}
