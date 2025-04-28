import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';

class RouteCard extends StatelessWidget {
  final String startTime;
  final String endTime;
  final String duration;
  final String startLocation;
  final String startAddress;
  final String endLocation;
  final String endAddress;
  final String seatInfo;
  final String price;
  final Function()? onStartPressed;

  const RouteCard({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.duration,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
    required this.seatInfo,
    required this.price,
    this.onStartPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Main content row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side with time and timeline
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    startTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: mainButtonColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
                    color: Colors.grey.shade300,
                  ),
                  Text(
                    duration,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 30,
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
                  const SizedBox(height: 5),
                  Text(
                    endTime,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87
                    ),
                  ),
                ],
              ),
              
              const SizedBox(width: 30),
              
              // Middle section with locations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          startLocation,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.black87
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.location_on,
                          color: companyColor,
                          size: 26,
                        ),
                      ],
                    ),
                    Text(
                      startAddress,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 70),
                    Text(
                      endLocation,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.black87
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
          
          const SizedBox(height: 25),
          
          // Bottom row with three columns - separate from the main row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // First column - Seat info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.airline_seat_recline_normal, size: 16, color: companyColor),
                    const SizedBox(width: 5),
                    Text(seatInfo, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              
              // Second column - Price
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_money, size: 16, color: mainButtonColor),
                    const SizedBox(width: 5),
                    Text(price, style: const TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              
              // Third column - Start button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: onStartPressed,
                child: const Text('Start', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}