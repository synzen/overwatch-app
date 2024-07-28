class GeoServicePosition {
  final String lat;
  final String long;

  GeoServicePosition({required this.lat, required this.long});

  factory GeoServicePosition.fromJson(Map<String, dynamic> json) {
    return GeoServicePosition(lat: json['lat'], long: json['long']);
  }
}

class GeoService {
  Future<GeoServicePosition> determinePosition() async {
    return GeoServicePosition(lat: "12", long: "12");
  }
}
