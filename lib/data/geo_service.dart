class GeoServicePosition {
  final String lat;
  final String long;

  GeoServicePosition({required this.lat, required this.long});
}

class GeoService {
  Future<GeoServicePosition> determinePosition() async {
    return GeoServicePosition(lat: "12", long: "12");
  }
}
