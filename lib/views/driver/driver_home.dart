import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/driver/post_a_ride.dart';
import 'package:mobile_frontend/widgets/last_trip_item.dart';
import 'package:mobile_frontend/models/last_trip.dart';
import 'package:mobile_frontend/widgets/route_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

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
    refreshData(); // Trigger refresh on load
  }

  Future<void> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Driver';
    });
  }

  Future<void> fetchRides() async {
    try {
      List<Ride> fetchedRides = await RideService.fetchDriverRides();

      // Get today and tomorrow in DD/MM/YYYY format
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String today = formatter.format(DateTime.now());
      final String tomorrow = formatter.format(
        DateTime.now().add(Duration(days: 1)),
      );

      // Filter rides for today and tomorrow
      List<Ride> filteredRides =
          fetchedRides.where((ride) {
            return ride.date == today || ride.date == tomorrow;
          }).toList();

      print('Filtered rides: $filteredRides');
      setState(() {
        rides = filteredRides;
      });
    } catch (e) {
      print('Error fetching rides: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching rides: $e')));
    }
  }

  Future<void> fetchLastTrips() async {
    try {
      final storage = FlutterSecureStorage();
      final List<Ride> completedRides = await RideService.fetchDriverCompleted(
        storage,
      );

      setState(() {
        lastTrips =
            completedRides
                .map(
                  (ride) => LastTrip(
                    locationName:
                        ride.pickupLocation, 
                    address:
                        ride.dropoffLocation, 
                  ),
                )
                .toList();
      });
    } catch (e) {
      print('Error fetching last trips: $e');
      setState(() {
        lastTrips = []; 
      });
    }
  }

  Future<void> refreshData() async {
    setState(() {
      isLoading = true;
    });
    await Future.wait([fetchRides(), fetchLastTrips()]);
    setState(() {
      isLoading = false;
    });
  }

  Widget _buildLastTripPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 5),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
            ),
            title: Container(width: 150, height: 16, color: Colors.white),
            subtitle: Container(width: 200, height: 14, color: Colors.white),
            trailing: Container(width: 60, height: 16, color: Colors.white),
          ),
          Divider(color: Colors.grey.shade300, thickness: 1.0, height: 1.0),
        ],
      ),
    );
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
              padding: const EdgeInsets.only(
                left: 20.0,
                right: 20.0,
                top: 50,
                bottom: 30,
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
                  top: 20.0,
                  bottom: 10.0,
                  left: 15.0,
                  right: 15.0,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                child: RefreshIndicator(
                  onRefresh: refreshData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Upcoming Rides",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: blackWithOpacity,
                          ),
                        ),
                        SizedBox(height: 15),
                        isLoading
                            ? SizedBox(
                              height: 210,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: 3, // Show 3 placeholder cards
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      right: 15.0,
                                      left: 0,
                                    ),
                                    child: SizedBox(
                                      width: screenWidth * 0.95,
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey[300]!,
                                        highlightColor: Colors.grey[100]!,
                                        child: Card(
                                          elevation: 4,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Container(
                                            padding: EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  height: 20,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(height: 10),
                                                Container(
                                                  width: 150,
                                                  height: 16,
                                                  color: Colors.white,
                                                ),
                                                SizedBox(height: 10),
                                                Container(
                                                  width: 100,
                                                  height: 16,
                                                  color: Colors.white,
                                                ),
                                                Spacer(),
                                                Container(
                                                  width: 80,
                                                  height: 36,
                                                  color: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                            : rides.isEmpty
                            ? Center(child: Text('No active rides found'))
                            : SizedBox(
                              height: 210,
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
                                      width: screenWidth * 0.95,
                                      child: RouteCard(
                                        rideId: ride.id,
                                        Date: ride.date,
                                        startTime: ride.startTime,
                                        duration: ride.duration,
                                        startLocation: ride.pickupLocation,
                                        endLocation: ride.dropoffLocation,
                                        peopleJoined:
                                            '${ride.passengerCount}/${ride.seatingCapacity}',
                                        passengers: ride.passengers,
                                        onStartPressed: () {
                                          print('Start pressed ${ride.id}');
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        SizedBox(height: 30),
                        const Text(
                          "Last Rides",
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
                        isLoading
                            ? Column(
                              children: List.generate(
                                3, // Show 3 placeholder last trip items
                                (index) => _buildLastTripPlaceholder(),
                              ),
                            )
                            : lastTrips.isEmpty
                            ? Center(child: Text('No last rides found'))
                            : Column(
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
            ),
          ],
        ),
      ),
    );
  }
}
