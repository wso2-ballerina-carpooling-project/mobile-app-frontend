import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/views/driver/ride_detail_screen.dart'; // Adjust import path

class SimpleRideCard extends StatelessWidget {
  final Ride ride;

  const SimpleRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final startLocation = ride.pickupLocation;
    final endLocation = ride.dropoffLocation;
    final passengerCount = ride.passengerCount;
    final startTime = ride.startTime;
    final date = ride.date;

    // Calculate total earnings based on passenger costs
    final totalEarnings = ride.passengers.isNotEmpty
        ? ride.passengers.map((passenger) => passenger.cost).reduce((a, b) => a + b)
        : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RideDetailScreen(ride: ride),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border(
            bottom: BorderSide(
              color: Colors.grey[400]!,
              width: 1.0,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                startLocation,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                endLocation,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Earn: Rs. ${totalEarnings.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 16, color: Colors.green[700]),
                  ),
                  Text(
                    'Passengers: $passengerCount',
                    style: const TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: $date',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  Text(
                    'Time: $startTime',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}