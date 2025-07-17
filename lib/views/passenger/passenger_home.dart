import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart'; // Updated import
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/passenger/find_a_ride_screen.dart';
import 'package:mobile_frontend/widgets/last_trip_item.dart';
import 'package:mobile_frontend/models/last_trip.dart';
import 'package:mobile_frontend/widgets/passender_route_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  bool isRideStarted = true;
  String? firstName;
  List<Ride> rides = [];
  List<LastTrip> lastTrips = [];
  bool isLoading = true;
  String? loggedInPassengerId; // To store the logged-in passenger ID

  @override
  void initState() {
    super.initState();
    getUserDetails();
    getLoggedInPassengerId(); // Fetch logged-in passenger ID
    refreshData(); // Trigger refresh on load
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

  Future<void> fetchLastTrips() async {
    try {
      final storage = FlutterSecureStorage();
      final List<Ride> completedRides =
          await RideService.fetchPassengerCompleted(storage);

      setState(() {
        lastTrips = completedRides.map((ride) {
          final passenger = ride.passengers.firstWhere(
            (p) => p.passengerId == loggedInPassengerId,
          );

          return LastTrip(
            locationName: ride.waytowork ? ride.dropoffLocation: passenger.address,
            address: ride.waytowork ? passenger.address : ride.pickupLocation,
            cost: "LKR ${passenger.cost.toStringAsFixed(2)}", // Use passenger cost
          );
        }).toList().take(4).toList();
      });
    } catch (e) {
      print('Error fetching last trips: $e');
      setState(() {
        lastTrips = [];
      });
    }
  }

  Future<void> fetchRides() async {
    try {
      final storage = FlutterSecureStorage();
      final List<Ride> fetchedRides = await RideService.fetchPassengerOngoing(
        storage,
      ); // Directly as List<Ride>
      print(fetchedRides);
      // Get today and tomorrow in DD/MM/YYYY format
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      final String today = formatter.format(DateTime.now()); // 14/07/2025
      final String tomorrow = formatter.format(
        DateTime.now().add(const Duration(days: 1)),
      ); // 15/07/2025

      // Filter rides for today and tomorrow
      List<Ride> filteredRides =
          fetchedRides.where((ride) {
            return ride.date == today || ride.date == tomorrow;
          }).toList();

      print(filteredRides);

      // Sort by date and startTime (earliest first)
      filteredRides.sort((a, b) {
        final dateTimeA = DateFormat(
          'dd/MM/yyyy HH:mm',
        ).parse('${a.date} ${a.startTime}');
        final dateTimeB = DateFormat(
          'dd/MM/yyyy HH:mm',
        ).parse('${b.date} ${b.startTime}');
        return dateTimeA.compareTo(dateTimeB);
      });

      // Take up to 2 nearest rides
      final nearestRides = filteredRides.take(2).toList();

      print('Nearest rides: $nearestRides');
      setState(() {
        rides = nearestRides;
      });
    } catch (e) {
      print('Error fetching rides: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching rides: $e')));
    }
  }

  void trackRide() {
    debugPrint('Tracking ride...');
  }

  Future<void> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Driver';
    });
  }

  Future<void> getLoggedInPassengerId() async {
     final prefs = await SharedPreferences.getInstance();
    // Assuming passengerId is stored in secure storage (adjust key as per your app)
    final passengerId = await prefs.getString("id");
    setState(() {
      loggedInPassengerId = passengerId; // Default to example ID
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
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 30,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hi, ${firstName ?? '...'}!",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
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
                                            child: RouteCardPassenger(
                                              startLocation:
                                                  ride.pickupLocation,
                                              startAddress: ride.pickupLocation,
                                              endLocation:
                                                  ride.dropoffLocation,
                                              endAddress: ride.dropoffLocation,
                                              date: ride.date,
                                              time: ride.startTime,
                                              isRideStarted: ride.status == 'active',
                                              isGoingToWork: ride.waytowork,
                                              onTrackPressed: trackRide,
                                              ride: ride,
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