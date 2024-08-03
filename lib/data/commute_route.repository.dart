import 'package:flutter/foundation.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:sqflite/sqflite.dart';

class CommuteRoute {
  final String name;
  final List<CommuteRouteStop> stops;

  CommuteRoute({required this.name, required this.stops});

  @override
  String toString() {
    return 'CommuteRoute{id: $name, name: $stops}';
  }
}

class CommuteRouteStop {
  final String id;
  final String routeId;

  CommuteRouteStop({required this.id, required this.routeId});

  String get hashKey => "$id-$routeId";

  @override
  String toString() {
    return 'CommuteRouteStop{id: $id, routeId: $routeId}';
  }
}

class DuplicateCommuteRouteException implements Exception {
  final String message = 'This name is already in use. Please choose another.';
}

class CommuteRouteRepository extends ChangeNotifier {
  Future<Database> database;

  CommuteRouteRepository(this.database);

  Future<void> insert(CommuteRoute commute) async {
    Database? db;
    try {
      db = await database;

      await db.execute("BEGIN TRANSACTION");
      await db.execute(
          "INSERT INTO commute_routes (name) VALUES (?)", [commute.name]);
      for (final stop in commute.stops) {
        await db.execute(
            "INSERT INTO commute_route_stops (commute_id, stop_id, route_id) VALUES ((SELECT last_insert_rowid()), ?, ?)",
            [stop.id, stop.routeId]);
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
        commute_route_stops.stop_id,
        commute_route_stops.route_id
        FROM commute_routes
        INNER JOIN commute_route_stops ON commute_routes.id = commute_route_stops.commute_id;
      """);

      final Map<String, List<CommuteRouteStop>> commutes = {};
      final Map<String, CommuteRouteStop> stops = {};

      for (final result in results) {
        // final commuteName = result['commute_route_name'] as String;
        final stopId = result['stop_id'] as String;
        final routeId = result['route_id'] as String;

        if (!stops.containsKey(stopId)) {
          stops[stopId] = CommuteRouteStop(id: stopId, routeId: routeId);
        }
      }

      for (final result in results) {
        final commuteName = result['commute_route_name'] as String;
        final stopId = result['stop_id'] as String;

        if (!commutes.containsKey(commuteName)) {
          commutes[commuteName] = [];
        }

        commutes[commuteName]!.add(stops[stopId]!);
      }

      return commutes.entries
          .map((entry) => CommuteRoute(name: entry.key, stops: entry.value))
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
