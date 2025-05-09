import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';

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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with Back button and Date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Back to work/home button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: companyColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => {},
                child: Text(
                  isGoingToWork ? 'Back to work' : 'Back to home',
                  style: const TextStyle(color: Colors.black, fontSize: 14),
                ),
              ),

              // Date and time box
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Route timeline and Track button
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Timeline with locations
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left side with timeline
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 60,
                          color: Colors.grey.shade300,
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: companyColor,
                            shape: BoxShape.rectangle,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 16),

                    // Locations
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            startLocation,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            startAddress,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 36),
                          Text(
                            endLocation,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            endAddress,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Track button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isRideStarted
                          ? mainButtonColor
                          : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isRideStarted ? onTrackPressed : null,
                child: const Text(
                  'Track',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}