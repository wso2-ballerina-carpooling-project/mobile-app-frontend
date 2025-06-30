import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RouteCard extends StatelessWidget {
  final String startTime;
  final String duration;
  final String startLocation;
  final String endLocation;
  final String peopleJoined; // e.g., "3/4"
  final String price;
  final Function()? onStartPressed;

  const RouteCard({
    super.key,
    required this.startTime,
    required this.duration,
    required this.startLocation,
    required this.endLocation,
    required this.peopleJoined,
    required this.price,
    this.onStartPressed,
  });

  // Helper method to calculate estimated start time (startTime - duration - 5 minutes)
  String _calculateEstimatedStartTime() {
    try {
      final DateFormat timeFormat = DateFormat('hh:mm a');
      final DateTime startDateTime = timeFormat.parse(startTime);

      final RegExp durationRegex = RegExp(r'(\d+)h\s*(\d*)m?');
      final match = durationRegex.firstMatch(duration);
      int hours = 0;
      int minutes = 0;

      if (match != null) {
        hours = int.parse(match.group(1)!);
        minutes = match.group(2)!.isNotEmpty ? int.parse(match.group(2)!) : 0;
      }

      final totalMinutes = (hours * 60 + minutes + 5);
      final estimatedTime = startDateTime.subtract(Duration(minutes: totalMinutes));

      return timeFormat.format(estimatedTime);
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF4A90E2); // Blue from the image
    const textColor = Colors.white;
    const buttonColor = Color(0xFF50E3C2); // Greenish button color
    const infoBgColor = Color(0x33FFFFFF); // Semi-transparent white for background

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
            'Est. ${_calculateEstimatedStartTime()}',
            style: const TextStyle(
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 12),
          // Body: Locations
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: textColor, size: 20),
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
                      style: const TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
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
              // People Joined
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: infoBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$peopleJoined joined',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              // Price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: infoBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  price,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
              ),
              // Start Button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                onPressed: onStartPressed,
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