class GetTransitStopsAtLocation {
  Data data;
  bool isHighAccuracy;

  GetTransitStopsAtLocation({required this.data, required this.isHighAccuracy});

  factory GetTransitStopsAtLocation.fromJson(Map<String, dynamic> json,
      {required bool isHighAccuracy}) {
    return GetTransitStopsAtLocation(
        data: Data.fromJson(json['data']), isHighAccuracy: isHighAccuracy);
  }
}

class Data {
  List<Route> routes;

  Data({required this.routes});

  factory Data.fromJson(Map<String, dynamic> json) {
    var routes = <Route>[];
    json['routes'].forEach((v) {
      routes.add(Route.fromJson(v));
    });

    return Data(routes: routes);
  }
}

class Route {
  String name;
  List<Grouping> groupings;

  Route({
    required this.name,
    required this.groupings,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    var groupings = <Grouping>[];
    json['groupings'].forEach((v) {
      groupings.add(Grouping.fromJson(v));
    });

    return Route(name: json['name'], groupings: groupings);
  }
}

class Grouping {
  String name;
  List<Stop> stops;

  Grouping({required this.name, required this.stops});

  factory Grouping.fromJson(Map<String, dynamic> json) {
    var stops = <Stop>[];
    json['stops'].forEach((v) {
      stops.add(Stop.fromJson(v));
    });

    return Grouping(stops: stops, name: json['name']);
  }
}

class Stop {
  String id;
  String name;

  Stop({required this.id, required this.name});

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(id: json['id'], name: json['name']);
  }
}
