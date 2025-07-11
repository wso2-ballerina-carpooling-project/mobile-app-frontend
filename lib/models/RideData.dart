import 'package:google_maps_flutter/google_maps_flutter.dart';

class Ride {
  final String rideId;
  final String driverId;
  final String pickupLocation;
  final String dropoffLocation;
  final String date;
  final String startTime;
  final String duration;
  final String distance;
  final String status;
  final int seatingCapacity;
  final int seat;
  final int passengerCount;
  final String id;
  final String? reason;
  final bool waytowork;
  final List<Passenger> passengers;
  final Route route;

  Ride({
    required this.rideId,
    required this.driverId,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.date,
    required this.startTime,
    required this.duration,
    required this.distance,
    required this.status,
    required this.seatingCapacity,
    required this.seat,
    required this.passengerCount,
    required this.id,
    required this.reason,
    required this.waytowork,
    required this.passengers,
    required this.route,
  });

  factory Ride.fromJson(Map<String, dynamic> json, int seatingCapacity) {
    return Ride(
      rideId: json['rideId'] as String,
      driverId: json['driverId'] as String,
      pickupLocation: json['startLocation'] as String,
      dropoffLocation: json['endLocation'] as String,
      date: json['date'] as String,
      reason: json['reason'] as String?,
      startTime: json['time'] as String,
      duration: json['route']['duration'] as String,
      distance: json['route']['distance'] as String,
      status: json['status'] as String,
      seat: json['seat'] as int,
      seatingCapacity: seatingCapacity,
      passengerCount: (json['passengers'] as List<dynamic>).length,
      id: json['id'] as String,
      waytowork: json['waytowork'] as bool,
      passengers:
          (json['passengers'] as List<dynamic>)
              .map((p) => Passenger.fromJson(p))
              .toList(),
      route: Route.fromJson(json['route']),
    );
  }
}

class Passenger {
  final String passengerId;
  final LatLng waypoint;
  final DateTime bookingTime;
  final String status;
  final double cost;

  Passenger({
    required this.passengerId,
    required this.waypoint,
    required this.bookingTime,
    required this.status,
    required this.cost,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    final waypointJson = json['waypoint'] as Map<String, dynamic>;
    return Passenger(
      passengerId: json['passengerId'] as String,
      waypoint: LatLng(
        double.parse(waypointJson['latitude'] as String),
        double.parse(waypointJson['longitude'] as String),
      ),
      bookingTime: DateTime.parse(json['bookingTime'] as String),
      status: json['status'] as String,
      cost: json['cost'],
    );
  }
}

class Route {
  final int index;
  final String duration;
  final String distance;
  final List<LatLng> polyline;

  Route({
    required this.index,
    required this.duration,
    required this.distance,
    required this.polyline,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    return Route(
      index: json['index'] as int,
      duration: json['duration'] as String,
      distance: json['distance'] as String,
      polyline:
          (json['polyline'] as List<dynamic>)
              .map(
                (p) => LatLng(
                  double.parse(p['latitude'] as String),
                  double.parse(p['longitude'] as String),
                ),
              )
              .toList(),
    );
  }
}
