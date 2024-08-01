class GetTransitStopArrivalTime {
  Data data;

  GetTransitStopArrivalTime({required this.data});

  factory GetTransitStopArrivalTime.fromJson(Map<String, dynamic> json) {
    return GetTransitStopArrivalTime(data: Data.fromJson(json['data']));
  }

  toJson() {
    return {'data': data.toJson()};
  }
}

class Data {
  List<Arrival> arrivals;

  Data({required this.arrivals});

  factory Data.fromJson(Map<String, dynamic> json) {
    var arrivals = <Arrival>[];
    json['arrivals'].forEach((v) {
      arrivals.add(Arrival.fromJson(v));
    });

    return Data(arrivals: arrivals);
  }

  toJson() {
    return {'arrivals': arrivals.map((e) => e.toJson()).toList()};
  }
}

class Arrival {
  String expectedArrivalTime;
  int minutesUntilArrival;
  String routeLabel;

  Arrival(
      {required this.expectedArrivalTime,
      required this.minutesUntilArrival,
      required this.routeLabel});

  factory Arrival.fromJson(Map<String, dynamic> json) {
    return Arrival(
        expectedArrivalTime: json['expected_arrival_time'],
        minutesUntilArrival: json['minutes_until_arrival'],
        routeLabel: json['route_label']);
  }

  toJson() {
    return {
      'expected_arrival_time': expectedArrivalTime,
      'minutes_until_arrival': minutesUntilArrival,
      'route_label': routeLabel
    };
  }
}
