import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/driver/post_a_ride.dart';
import 'package:mobile_frontend/widgets/last_trip_item.dart';
import 'package:mobile_frontend/models/last_trip.dart';
import 'package:mobile_frontend/widgets/route_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String? firstName;
  List<Ride> rides = [];
  List<LastTrip> lastTrips = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getUserDetails();
    fetchRides();
    fetchLastTrips(); // Initialize last trips
  }

  Future<void> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Driver';
    });
  }

  Future<void> fetchRides() async {
    List<Ride> fetchedRides = await RideService.fetchDriverRides();
    print(fetchedRides);
    setState(() {
      rides = fetchedRides;
      isLoading = false;
    });
  }

  Future<void> fetchLastTrips() async {
    setState(() {
      lastTrips = [
        LastTrip(
          locationName: 'Lakewood Residence',
          address: '165/A8 Main Street, 11, Colombo',
        ),
        LastTrip(
          locationName: 'Marino Mall',
          address: 'No. 590, Galle Road, Colombo 03',
        ),
        LastTrip(
          locationName: 'Lakewood Residence',
          address: '165/A8 Main Street, 11, Colombo',
        ),
      ];
    });
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([fetchRides(), fetchLastTrips()]); // Refresh both sections
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, ${firstName ?? '...'}!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "Got a Seat to Share?",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RidePostScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: 30.0,
                  bottom: 10.0,
                  left: 15.0,
                  right: 15.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
                ),
                child: RefreshIndicator(
                  onRefresh: refreshData, // Trigger refresh for both sections
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(), // Ensure scrollable for refresh
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your routes",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: blackWithOpacity,
                          ),
                        ),
                        SizedBox(height: 15),
                        isLoading
                            ? Center(child: CircularProgressIndicator())
                            : rides.isEmpty
                                ? Center(child: Text('No active rides found'))
                                : Center(
                                    child: SizedBox(
                                      height:
                                          210, // Adjust height based on RouteCard size
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: rides.length,
                                        itemBuilder: (context, index) {
                                          final ride = rides[index];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              right: 15.0,
                                              left: 0,
                                            ),
                                            child: SizedBox(
                                              width: screenWidth * 1, // 80% of screen width per card
                                              child: RouteCard(
                                                startTime: ride.startTime,
                                                duration: ride.duration,
                                                startLocation: ride.pickupLocation,
                                                endLocation: ride.dropoffLocation,
                                                peopleJoined: '${ride.seatingCapacity - ride.seat}/${ride.seatingCapacity}',
                                                price: '\$45.00',
                                                onStartPressed: () {
                                                  print('Start pressed');
                                                },
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                        SizedBox(height: 30),
                        const Text(
                          "Your last trip",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: blackWithOpacity,
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
            ),
          ],
        ),
      ),
    );
  }
}

//Finishing one completed 