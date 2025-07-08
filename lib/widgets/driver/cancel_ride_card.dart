import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/RideData.dart';

class SimpleCancelRideCard extends StatelessWidget {
  final Ride ride;

  const SimpleCancelRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final startLocation = ride.pickupLocation;
    final endLocation = ride.dropoffLocation;
    final cancelReason = ride.reason ?? 'No reason provided'; // Assuming cancelReason is nullable
    final startTime = ride.startTime;
    final date = ride.date;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[400]!, // Gray color for bottom border
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
            Text(
              'Reason: $cancelReason',
              style: TextStyle(fontSize: 14, color: Colors.red[700]), // Highlight cancellation reason
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
    );
  }
}