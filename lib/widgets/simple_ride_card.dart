import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';

class SimpleRideCard extends StatelessWidget {
  final Ride ride;

  const SimpleRideCard({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    final startLocation = ride.pickupLocation;
    final endLocation = ride.dropoffLocation;
    final passengerCount = ride.passengerCount;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      color: const Color(0xFFf1f3f4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  'Earn: Rs. 500', // Placeholder earnings
                  style: TextStyle(fontSize: 16, color: Colors.green[700]),
                ),
                Text(
                  'Passengers: $passengerCount',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('View More clicked')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('View More', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}