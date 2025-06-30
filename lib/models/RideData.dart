import 'package:flutter/material.dart';

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
  final int seatingCapacity; // From driverDetails in JWT payload
  final int seat; // From driverDetails in JWT payload
  final int passengerCount; // From passengers array length
  final String id;

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
  });

  factory Ride.fromJson(Map<String, dynamic> json, int seatingCapacity) {
    return Ride(
      rideId: json['rideId'] as String,
      driverId: json['driverId'] as String,
      pickupLocation: json['startLocation'] as String,
      dropoffLocation: json['endLocation'] as String,
      date: json['date'] as String,
      startTime: json['time'] as String,
      duration: json['route']['duration'] as String,
      distance: json['route']['distance'] as String,
      status: json['status'] as String,
      seat: json['seat'] as int,
      seatingCapacity: seatingCapacity,
      passengerCount: (json['passengers'] as List<dynamic>).length,
      id: json['id'] as String,
    );
  }
}