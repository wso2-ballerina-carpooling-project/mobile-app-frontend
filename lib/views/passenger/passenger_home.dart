import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/views/passenger/find_a_ride_screen.dart';
import 'package:mobile_frontend/widgets/last_trip_item.dart';
import 'package:mobile_frontend/models/last_trip.dart';
import 'package:mobile_frontend/widgets/passender_route_card.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  bool isRideStarted = true;

  void trackRide() {
    // Implement ride tracking functionality
    debugPrint('Tracking ride...');
  }

  @override
  Widget build(BuildContext context) {
    final List<LastTrip> lastTrips = [
      LastTrip(
        locationName: 'Lakewood Residence',
        address: '165/A8 Main Street, 11,Colombo',
      ),
      LastTrip(
        locationName: 'Marino Mall',
        address: 'No. 590, Galle Road, Colombo 03',
      ),
      LastTrip(
        locationName: 'Lakewood Residence',
        address: '165/A8 Main Street, 11,Colombo',
      ),
      LastTrip(
        locationName: 'Lakewood Residence',
        address: '165/A8 Main Street, 11,Colombo',
      ),
    ];

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 30,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, John!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Need a Lift?",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.notifications,
                      color: Color(0xFF0F1736),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),
            // Search bar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FindARideScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.grey),
                      const SizedBox(width: 10),
                      const Text(
                        "Looking for lift?",
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  top: 20.0,
                  left: 20.0,
                  right: 20.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "Booking",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: blackWithOpacity,
                          ),
                        ),
                      ),
                      // Route cards in horizontal scroll
                      SizedBox(
                        height: 250,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            // First route card - Going to work
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.95,
                              child: RouteCardPassenger(
                                startLocation: 'University of Moratuwa',
                                startAddress: 'WSO2, Bandaranayake Mawatha, Colombo 03',
                                endLocation: 'WSO2',
                                endAddress: 'Bandaranayake Road',
                                date: '04/05/2025',
                                time: '9.00 am',
                                isRideStarted: true,
                                isGoingToWork: true,
                                onTrackPressed: trackRide,
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Second route card - Going home
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.85,
                              child: RouteCardPassenger(
                                startLocation: 'Moratuwa',
                                startAddress: 'Bandaranayake Road',
                                endLocation: 'WSO2',
                                endAddress: 'Bandaranayake Road',
                                date: '04/05/2025',
                                time: '10.00 pm',
                                isRideStarted: false,
                                isGoingToWork: false,
                                onTrackPressed: trackRide,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Padding(
                        padding: EdgeInsets.only(left: 8, bottom: 8),
                        child: Text(
                          "Your last trip",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: blackWithOpacity,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Last trips list
                      Column(
                        children:
                            lastTrips
                                .map((trip) => LastTripItem(trip: trip))
                                .toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
