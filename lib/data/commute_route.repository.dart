import 'package:flutter/foundation.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:sqflite/sqflite.dart';

class CommuteRoute {
  final String name;
  final List<String> stopIds;

  CommuteRoute({required this.name, required this.stopIds});

  @override
  String toString() {
    return 'CommuteRoute{id: $name, name: $stopIds}';
  }
}

class DuplicateCommuteRouteException implements Exception {
  final String message = 'This name is already in use. Please choose another.';
}

class CommuteRouteRepository extends ChangeNotifier {
  Future<Database> database;

  CommuteRouteRepository(this.database);

  Future<void> insert(CommuteRoute route) async {
    Database? db;
    try {
      db = await database;

      await db.execute("BEGIN TRANSACTION");
      await db.execute(
          "INSERT INTO commute_routes (name) VALUES (?)", [route.name]);
      for (final stopId in route.stopIds) {
        await db.execute(
            "INSERT INTO commute_route_stops (route_id, stop_id) VALUES ((SELECT last_insert_rowid()), ?)",
            [stopId]);
      }
      await db.execute("COMMIT TRANSACTION");

      notifyListeners();
    } on DatabaseException catch (e) {
      await db?.execute("ROLLBACK TRANSACTION");
      if (e.isUniqueConstraintError()) {
        throw DuplicateCommuteRouteException();
      }

      rethrow;
    } catch (e) {
      await db?.execute("ROLLBACK TRANSACTION");
      printForDebugging("Error inserting commute route: $e");

      rethrow;
    }
  }

  Future<List<CommuteRoute>> get() async {
    try {
      final db = await database;

      final results = await db.rawQuery("""
      SELECT
        commute_routes.name AS commute_route_name,
        commute_route_stops.stop_id
        FROM commute_routes
        INNER JOIN commute_route_stops ON commute_routes.id = commute_route_stops.route_id;
      """);

      final Map<String, List<String>> routes = {};

      for (final result in results) {
        final routeName = result['commute_route_name'] as String;
        final stopId = result['stop_id'] as String;

        if (!routes.containsKey(routeName)) {
          routes[routeName] = [];
        }

        routes[routeName]!.add(stopId);
      }

      return routes.entries
          .map((entry) => CommuteRoute(name: entry.key, stopIds: entry.value))
          .toList();
    } catch (e) {
      printForDebugging("Error fetching commute routes: $e");
      rethrow;
    }
  }

  Future<void> delete(int id) async {
    try {
      final db = await database;

      await db.delete(
        'commute_routes',
        where: "id = ?",
        whereArgs: [id],
      );

      notifyListeners();
    } catch (e) {
      printForDebugging("Error deleting commute route: $e");
      rethrow;
    }
  }
}
