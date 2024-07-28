import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:overwatchapp/utils/print_debug.dart';

class GeoServicePosition {
  final String lat;
  final String long;
  final bool isHighAccuracy;

  GeoServicePosition(
      {required this.lat, required this.long, required this.isHighAccuracy});

  factory GeoServicePosition.fromJson(Map<String, dynamic> json) {
    return GeoServicePosition(
        lat: json['lat'],
        long: json['long'],
        isHighAccuracy: json['isHighAccuracy']);
  }
}

class GeoService {
  Future<GeoServicePosition> determinePosition(
      {forcePermission = false}) async {
    bool serviceEnabled;
    LocationPermission permission;

    printForDebugging("Determining position...");

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      printForDebugging("service disabled");

      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || forcePermission) {
      printForDebugging("request permission");
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        printForDebugging("temp denied!!");
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      printForDebugging("permanently denied!!");
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    printForDebugging("Getting current position...");
    try {
      var pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10));
      printForDebugging("Got current position");

      printForDebugging("accuracy ${pos.accuracy}");
      return GeoServicePosition(
          lat: pos.latitude.toString(),
          long: pos.longitude.toString(),
          isHighAccuracy: pos.accuracy < 100);
    } on TimeoutException {
      var pos = await Geolocator.getLastKnownPosition();

      if (pos == null) {
        throw Exception(
            'Timed out while getting current position, and no known last position');
      }

      return GeoServicePosition(
          lat: pos.latitude.toString(),
          long: pos.longitude.toString(),
          isHighAccuracy: pos.accuracy < 100);
    } catch (e) {
      printForDebugging("Error getting position: $e");
      throw Exception('Error getting position');
    }
  }
}
