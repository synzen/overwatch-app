class GetTransitStopsForRoute {
  Data data;

  GetTransitStopsForRoute({required this.data});

  factory GetTransitStopsForRoute.fromJson(Map<String, dynamic> json) {
    return GetTransitStopsForRoute(data: Data.fromJson(json['data']));
  }
}

class Data {
  List<Group> groups;

  Data({required this.groups});

  factory Data.fromJson(Map<String, dynamic> json) {
    var groups = <Group>[];
    json['groups'].forEach((v) {
      groups.add(Group.fromJson(v));
    });

    return Data(groups: groups);
  }
}

class Group {
  String id;
  String name;
  List<Stop> stops;

  Group({required this.id, required this.name, required this.stops});

  factory Group.fromJson(Map<String, dynamic> json) {
    var stops = <Stop>[];
    json['stops'].forEach((v) {
      stops.add(Stop.fromJson(v));
    });

    return Group(id: json['id'], name: json['name'], stops: stops);
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
