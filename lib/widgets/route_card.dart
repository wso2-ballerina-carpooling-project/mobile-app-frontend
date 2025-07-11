import 'package:flutter/material.dart';
import 'package:mobile_frontend/models/RideData.dart';

class RouteCard extends StatelessWidget {
  final String startTime;
  final String Date;
  final String duration;
  final String startLocation;
  final String endLocation;
  final String peopleJoined;
  final String rideId;
  final List<Passenger> passengers;
  final Function()? onStartPressed;

  const RouteCard({
    super.key,
    required this.startTime,
    required this.Date,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.peopleJoined,
    required this.rideId,
    required this.passengers,
    this.onStartPressed,
  });

  String _calculateTotalCost() {
      if (passengers.isEmpty) {
        return 'LKR 0';
      }
      final totalCost = passengers.fold<double>(
        0,
        (sum, passenger) => sum + passenger.cost,
      );
      return 'LKR ${totalCost.toInt()}';
    }


  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFf1f3f4); // Blue from the image
    const textColor = Colors.black;
    const buttonColor = Color(0xFF1976d2); // Greenish button color
    const infoBgColor = Color(
      0xFFe5e7eb,
    ); // Semi-transparent white for background

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Time
          Text(
            startTime,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Date}',
            style: const TextStyle(fontSize: 14, color: textColor),
          ),
          const SizedBox(height: 12),
          // Body: Locations
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: textColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startLocation,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      endLocation,
                      style: const TextStyle(fontSize: 14, color: textColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Footer: People Joined, Price, and Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: infoBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$peopleJoined joined',
                      style: const TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Price
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: infoBgColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                       _calculateTotalCost(),
                      style: const TextStyle(fontSize: 14, color: textColor),
                    ),
                  ),
                ],
              ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(80, 30),
                ),
                onPressed: () {
                  // Navigate to RideStartScreen with rideId
                  Navigator.pushNamed(
                    context,
                    '/rideStart',
                    arguments:
                        '01f058d9-3fcc-1818-b755-49cf5bdba5f3', // Replace with actual rideId
                  );
                },
                child: const Text(
                  'Start',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
