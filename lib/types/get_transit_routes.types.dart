class GetTransitRoutesResponse {
  Data data;

  GetTransitRoutesResponse({required this.data});

  factory GetTransitRoutesResponse.fromJson(Map<String, dynamic> json) {
    return GetTransitRoutesResponse(data: Data.fromJson(json['data']));
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
  String id;
  String name;

  Route({required this.id, required this.name});

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(id: json['id'], name: json['name']);
  }
}