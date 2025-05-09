import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_frontend/models/user.dart';

class RideData {
  // Core ride information
  final String rideId;
  final String driverId;
  final int noOfPassengers;

  final DateTime date;
  final DateTime arrivalTime;
  final DateTime startTime;
  DateTime? endTime; 

  final LatLng origin;
  final LatLng destination;
  final List<LatLng> waypoints;

  String status; 
  int currentWaypointIndex; 
  LatLng? currentLocation; 

  final List<User> passengers;

  RideData({
    required this.rideId,
    required this.driverId,
    required this.noOfPassengers,
    required this.date,
    required this.arrivalTime,
    required this.startTime,
    this.endTime,
    required this.origin,
    required this.destination,
    required this.waypoints,
    this.status = "scheduled",
    this.currentWaypointIndex = 0,
    this.currentLocation,
    this.passengers = const [],
  });
}
