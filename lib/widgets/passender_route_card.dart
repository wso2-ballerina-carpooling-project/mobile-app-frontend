import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/passenger/passenger_ride_tracking.dart';

class RouteCardPassenger extends StatelessWidget {
  final String startLocation;
  final String startAddress;
  final String endLocation;
  final String endAddress;
  final String date;
  final String time;
  final bool isRideStarted;
  final bool isGoingToWork;
  final Function()? onTrackPressed;

  const RouteCardPassenger({
    super.key,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
    required this.date,
    required this.time,
    this.isRideStarted = true,
    this.isGoingToWork = true,
    this.onTrackPressed,
  });

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFf1f3f4); // Matching RouteCard's background
    const textColor = Colors.black; // Primary text color
    const buttonColor = Color(0xFF1976d2); // Matching RouteCard's button color
    const infoBgColor = Color(0xFFe5e7eb); // Background for info chips

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: infoBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isGoingToWork ? 'Back to work' : 'Back to home',
                  style: const TextStyle(fontSize: 14, color: textColor),
                ),
              ),
              // Date and time chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: infoBgColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(fontSize: 14, color: textColor),
                    ),
                    Text(
                      time,
                      style: const TextStyle(fontSize: 14, color: textColor),
                    ),
                  ],
                ),
              ),
            ],
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
                   
                    const SizedBox(height: 8),
                    Text(
                      endLocation,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
          // Footer: Track Button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(80, 30),
                ),
                onPressed: isRideStarted
                    ? () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return const PassengerRideTracking();
                          },
                        );
                        if (onTrackPressed != null) {
                          onTrackPressed!();
                        }
                      }
                    : null,
                child: const Text(
                  'Track Ride',
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