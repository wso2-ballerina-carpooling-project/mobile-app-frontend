import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'map_sample.dart'; 

class RideDetailsScreen extends StatefulWidget {
  const RideDetailsScreen({Key? key}) : super(key: key);

  @override
  State<RideDetailsScreen> createState() => _RideDetailsScreenState();
}

class _RideDetailsScreenState extends State<RideDetailsScreen> {
  // Sample data (will be fetched from backend later)
  String driverName = 'John Wick';
  String vehicle = 'Jeep Compass - CBL 8090';
  String pickupLocation = 'Moratuwa';
  String dropOffLocation = 'WSO2';
  int availableSeats = 1;
  int totalSeats = 5;
  String profileImageUrl = 'https://i.pravatar.cc/300';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A), // Deep Blue Background
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    ),
                  ),
                  const Text(
                    'Ride Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Picture and Name
            const SizedBox(height: 10),
            CircleAvatar(
              radius: 40,
              backgroundImage: NetworkImage(profileImageUrl),
            ),
            const SizedBox(height: 10),
            Text(
              driverName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            // Ride Information Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _infoCard(title: vehicle),
                  const SizedBox(height: 10),
                  _infoCard(title: 'From: $pickupLocation'),
                  const SizedBox(height: 10),
                  _infoCard(title: 'To: $dropOffLocation'),
                  const SizedBox(height: 10),
                  
                  // Seats Available Row
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _infoCard(title: 'Seats Available'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(255, 34, 16, 136).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1), // Soft black shadow
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              '$availableSeats/$totalSeats',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Map
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: const MapSample(),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Book Now Button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CustomButton(
                text: 'Book Now',
                backgroundColor: Colors.green,
                onPressed: () {
                  // Book action
                  print('Booking the ride...');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String title}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 34, 16, 136).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Soft black shadow
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
