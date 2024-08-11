import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:overwatchapp/utils/print_debug.dart';
import 'package:sqflite/sqflite.dart';

class CommuteRoute {
  final String name;
  final int id;
  final List<CommuteRouteStop> stops;

  CommuteRoute({required this.id, required this.name, required this.stops});

  @override
  String toString() {
    return 'CommuteRoute{id: $name, name: $stops}';
  }
}

class NewCommuteRoute {
  final String name;
  final List<CommuteRouteStop> stops;

  NewCommuteRoute({required this.name, required this.stops});

  @override
  String toString() {
    return 'CommuteRoute{id: $name, name: $stops}';
  }
}

class CommuteRouteStop {
  final String id;
  final String routeId;
  final String routeName;

  CommuteRouteStop(
      {required this.id, required this.routeId, required this.routeName});

  String get hashKey => "$id-$routeId";

  @override
  String toString() {
    return 'CommuteRouteStop{id: $id, routeId: $routeId, routeName: $routeName}';
  }

  String toJson() {
    return jsonEncode({
      'id': id,
      'routeId': routeId,
      'routeName': routeName,
    });
  }

  factory CommuteRouteStop.fromJson(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);

    return CommuteRouteStop(
        id: json['id'], routeId: json['routeId'], routeName: json['routeName']);
  }
}

class DuplicateCommuteRouteException implements Exception {
  final String message = 'This name is already in use. Please choose another.';
}

class CommuteRouteRepository extends ChangeNotifier {
  Future<Database> database;

  CommuteRouteRepository(this.database);

  Future<void> insert(NewCommuteRoute commute) async {
    Database? db;
    try {
      db = await database;

      await db.execute("BEGIN TRANSACTION");
      await db.execute(
          "INSERT INTO commute_routes (name) VALUES (?)", [commute.name]);

      for (final stop in commute.stops) {
        await db.execute(
            "INSERT INTO commute_route_stops (commute_id, stop_id, route_id, route_name) VALUES ((SELECT last_insert_rowid()), ?, ?, ?)",
            [stop.id, stop.routeId, stop.routeName]);
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
        commute_routes.id AS commute_id,
        commute_routes.name AS commute_route_name,
        commute_route_stops.stop_id,
        commute_route_stops.route_id,
        commute_route_stops.route_name
        FROM commute_routes
        INNER JOIN commute_route_stops ON commute_routes.id = commute_route_stops.commute_id;
      """);

      // final Map<String, List<CommuteRouteStop>> commutes = {};
      final Map<int, List<CommuteRouteStop>> stopsByCommuteId = {};
      final Map<int, CommuteRoute> routes = {};

      for (final result in results) {
        final stopId = result['stop_id'] as String;
        final routeId = result['route_id'] as String;
        final routeName = result['route_name'] as String;
        final commuteId = result['commute_id'] as int;

        if (!stopsByCommuteId.containsKey(commuteId)) {
          stopsByCommuteId[commuteId] = [];
        }

        stopsByCommuteId[commuteId]!.add(CommuteRouteStop(
            id: stopId, routeId: routeId, routeName: routeName));
      }

      for (final result in results) {
        final commuteId = result['commute_id'] as int;
        final commuteName = result['commute_route_name'] as String;

        if (!routes.containsKey(commuteId)) {
          routes[commuteId] = CommuteRoute(
              id: commuteId,
              name: commuteName,
              stops: stopsByCommuteId[commuteId]!);
        }
      }

      return routes.values.toList();
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
