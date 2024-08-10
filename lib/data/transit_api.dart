import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:overwatchapp/data/geo_service.dart';
import 'package:overwatchapp/types/get_transit_routes.types.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:overwatchapp/types/get_transit_stop_for_route.types.dart';
import 'package:overwatchapp/types/get_transit_stops_at_location.types.dart';
import 'package:overwatchapp/utils/print_debug.dart';

class TransitApi {
  final String baseUrl;
  final String apiKey;
  final GeoService geoService;
  GetTransitStopsAtLocation? _cachedStopsAtLocation;

  TransitApi(
      {required this.baseUrl, required this.apiKey, required this.geoService});

  factory TransitApi.fromEnv() {
    var apiUrl = dotenv.env['API_URL'];
    var apiKey = dotenv.env['API_KEY'];

    if (apiUrl == null || apiKey == null) {
      throw Exception('API_URL and API_KEY must be set in .env file');
    }

    return TransitApi(
        baseUrl: apiUrl, apiKey: apiKey, geoService: GeoService());
  }

  Future<GetTransitRoutesResponse> fetchTransitRoutes(String search) async {
    if (search.isEmpty) {
      throw Exception('Search query cannot be empty');
    }

    try {
      final response = await http.get(
          Uri.parse(
              '$baseUrl/transit-routes?search=${Uri.encodeComponent(search)}'),
          headers: {'Temp-Authorization': apiKey});

      if (response.statusCode == 200) {
        return GetTransitRoutesResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        if (kDebugMode) {
          debugPrint(
              "Non-200 status code returned from server: ${response.statusCode}");
        }
        throw Exception('Bad status code ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching transit routes: $e");
      }

      rethrow;
    }
  }

  Future<GetTransitStopsAtLocation> fetchTransitStopsAtLocation(
      {promptForLocationPermission = false}) async {
    if (_cachedStopsAtLocation != null && !promptForLocationPermission) {
      return _cachedStopsAtLocation!;
    }

    var position = await geoService.determinePosition(
        forcePermission: promptForLocationPermission);
    printForDebugging('Position: ${position.lat}, ${position.long}');
    try {
      final response = await http.get(
          Uri.parse(
              '$baseUrl/transit-stops-at-location?coordinates=${Uri.encodeComponent(position.lat)},${Uri.encodeComponent(position.long)}'),
          headers: {'Temp-Authorization': apiKey});

      if (response.statusCode == 200) {
        var val = GetTransitStopsAtLocation.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
            isHighAccuracy: position.isHighAccuracy);

        _cachedStopsAtLocation = val;

        // expire in 5 min
        Future.delayed(const Duration(minutes: 5), () {
          _cachedStopsAtLocation = null;
        });

        return val;
      } else {
        if (kDebugMode) {
          debugPrint(
              "Non-200 status code returned from server: ${response.statusCode}");
        }
        throw Exception(
            'Bad status code ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching transit routes: $e");
      }

      rethrow;
    }
  }

  Future<GetTransitStopsForRoute> fetchStops(String routeId) async {
    try {
      final response = await http.get(
          Uri.parse(
              '$baseUrl/transit-stops-for-route?route_id=${Uri.encodeComponent(routeId)}'),
          headers: {'Temp-Authorization': apiKey});

      if (response.statusCode == 200) {
        return GetTransitStopsForRoute.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        if (kDebugMode) {
          debugPrint(
              "Non-200 status code returned from server: ${response.statusCode}");
        }
        throw Exception('Bad status code: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching transit routes: $e");
      }

      rethrow;
    }
  }

  Future<GetTransitStopArrivalTime> fetchArrivalTimes(
      List<String> stopIds, List<String> routeIds) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/transit-arrival-times?stop_ids=${Uri.encodeComponent(stopIds.join(','))}&route_ids=${Uri.encodeComponent(routeIds.join(','))}');

      printForDebugging('Fetching arrival times from $uri');
      final response =
          await http.get(uri, headers: {'Temp-Authorization': apiKey});

      if (response.statusCode == 200) {
        return GetTransitStopArrivalTime.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        printForDebugging(
            "Non-200 status code returned from server: ${response.statusCode}");
        throw Exception('Bad status code: ${response.statusCode}');
      }
    } catch (e) {
      printForDebugging("Error fetching transit routes: $e");

      rethrow;
    }
  }
}
