import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/last_trip_item.dart';
import 'package:mobile_frontend/models/last_trip.dart';
import 'package:mobile_frontend/widgets/route_card.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<LastTrip> lastTrips = [
      LastTrip(locationName: 'Lakewood Residence', address: '165/A8 Main Street, 11, Colombo'),
      LastTrip(locationName: 'Marino Mall', address: 'No. 590, Galle Road, Colombo 03'),
      LastTrip(locationName: 'Lakewood Residence', address: '165/A8 Main Street, 11, Colombo'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0F1736),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, Nalaka!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Got a Seat to Share?",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 32),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: 30.0,
                  bottom: 10.0,
                  left: 20.0,
                  right: 20.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Your routes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: blackWithOpacity
                        ),
                      ),
                      const SizedBox(height: 15),
                      RouteCard(
                        startTime: "08:00",
                        endTime: "09:10",
                        duration: "1h 10min(est)",
                        startLocation: "Moratuwa",
                        startAddress: "Bandaranayake Road",
                        endLocation: "WSO2",
                        endAddress: "Bandaranayake Road",
                        seatInfo: "2/4",
                        price: "Rs.1200",
                        onStartPressed: () {
                          Navigator.of(context).pushReplacementNamed('/rideStart');
                        },
                      ),
                      const SizedBox(height: 30),
                      const Text(
                        "Your last trip",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: blackWithOpacity
                        ),
                      ),
                      const SizedBox(height: 15),
                       Divider(
                        color: Colors.grey.shade300,
                        thickness: 1.0,
                        height: 1.0,
                      ),
                      Column(
                        children: lastTrips
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
