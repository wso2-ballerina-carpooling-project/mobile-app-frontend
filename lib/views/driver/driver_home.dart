import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/views/driver/post_a_ride.dart';
import 'package:mobile_frontend/widgets/last_trip_item.dart';
import 'package:mobile_frontend/models/last_trip.dart';
import 'package:mobile_frontend/widgets/route_card.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  String? firstName;
  List<Ride> rides = [];
  bool isLoading = true;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    getUserDetails();
    fetchRides();
  }

  Future<void> getUserDetails() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName') ?? 'Driver';
    });
  }

  Future<void> fetchRides() async {
    try {
      // Retrieve JWT token
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Decode JWT to get seating capacity
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      int seatingCapacity = int.parse(
        payload['driverDetails']['seatingCapacity'].toString(),
      );

      // Make API call
      final response = await http.post(
        Uri.parse('http://192.168.234.103:9090/api/getRide'),
        headers: {'Authorization': 'Bearer $token'},
      );
      print(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rides'];
        setState(() {
          rides = rideList
              .map((rideJson) => Ride.fromJson(rideJson, seatingCapacity))
              .where((ride) => ride.status == 'active')
              .toList();
          isLoading = false;
        });
      } else {
        print('Failed to fetch rides: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching rides: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<LastTrip> lastTrips = [
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
                          color: blackWithOpacity,
                        ),
                      ),
                      const SizedBox(height: 15),
                      isLoading
                          ? Center(child: CircularProgressIndicator())
                          : rides.isEmpty
                              ? Center(child: Text('No active rides found'))
                              : SizedBox(
                                  height: 260, // Adjust height based on RouteCard size
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: rides.length,
                                    itemBuilder: (context, index) {
                                      final ride = rides[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 15.0),
                                        child: SizedBox(
                                          width: screenWidth * 0.8, // 80% of screen width per card
                                          child: RouteCard(
                                            startTime: ride.startTime,
                                            endTime: ride.returnTime,
                                            duration: ride.duration,
                                            startLocation: ride.pickupLocation.split(',')[0],
                                            startAddress: ride.pickupLocation,
                                            endLocation: ride.dropoffLocation.split(',')[0],
                                            endAddress: ride.dropoffLocation,
                                            seatInfo: '${ride.passengerCount}/${ride.seatingCapacity}',
                                            price: 'Rs.${(ride.passengerCount * 600).toString()}', // Placeholder pricing
                                            onStartPressed: () {
                                              Navigator.of(context).pushReplacementNamed('/rideStart');
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                      const SizedBox(height: 30),
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
                        children: lastTrips.map((trip) => LastTripItem(trip: trip)).toList(),
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