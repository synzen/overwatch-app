import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:overwatchapp/types/get_transit_routes.types.dart';
import 'package:overwatchapp/types/get_transit_stop_arrival_time.types.dart';
import 'package:overwatchapp/types/get_transit_stop_for_route.types.dart';
import 'package:overwatchapp/utils/print_debug.dart';

class TransitApi {
  final String baseUrl;
  final String apiKey;

  TransitApi({required this.baseUrl, required this.apiKey});

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
        throw Exception('Failed to load transit routes');
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
        throw Exception('Failed to load transit routes');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint("Error fetching transit routes: $e");
      }

      rethrow;
    }
  }

  Future<GetTransitStopArrivalTime> fetchArrivalTime(String stopId) async {
    try {
      final response = await http.get(
          Uri.parse(
              '$baseUrl/transit-arrival-times?stop_id=${Uri.encodeComponent(stopId)}'),
          headers: {'Temp-Authorization': apiKey});

      if (response.statusCode == 200) {
        return GetTransitStopArrivalTime.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        printForDebugging(
            "Non-200 status code returned from server: ${response.statusCode}");
        throw Exception('Failed to load transit routes');
      }
    } catch (e) {
      printForDebugging("Error fetching transit routes: $e");

      rethrow;
    }
  }
}
