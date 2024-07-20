class GetTransitStopArrivalTime {
  Data data;

  GetTransitStopArrivalTime({required this.data});

  factory GetTransitStopArrivalTime.fromJson(Map<String, dynamic> json) {
    return GetTransitStopArrivalTime(data: Data.fromJson(json['data']));
  }
}

class Data {
  Arrival? arrival;

  Data({required this.arrival});

  factory Data.fromJson(Map<String, dynamic> json) {
    return Data(
        arrival:
            json['arrival'] != null ? Arrival.fromJson(json['arrival']) : null);
  }
}

class Arrival {
  String expectedArrivalTime;
  int minutesUntilArrival;

  Arrival(
      {required this.expectedArrivalTime, required this.minutesUntilArrival});

  factory Arrival.fromJson(Map<String, dynamic> json) {
    return Arrival(
        expectedArrivalTime: json['expected_arrival_time'],
        minutesUntilArrival: json['minutes_until_arrival']);
  }
}
