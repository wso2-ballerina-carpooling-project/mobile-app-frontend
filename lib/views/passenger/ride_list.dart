import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/models/user.dart';
import 'package:mobile_frontend/views/passenger/ride_details.dart';
import 'package:mobile_frontend/views/passenger/ride_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math' as math;

class RideListScreen extends StatefulWidget {
  final List<Map<String, dynamic>> rides;
  final String waypoint;
  final LatLng? waypointLatLng;
  final bool waytowork;
  final String date;

  const RideListScreen({
    Key? key,
    required this.rides,
    required this.waypoint,
    required this.waypointLatLng,
    required this.waytowork,
    required this.date,
  }) : super(key: key);

  @override
  _RideListScreenState createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen> {
  final storage = FlutterSecureStorage();
  final DateTime currentDateTime =
      DateTime.now(); // Updated to 03:58 PM +0530, July 12, 2025
  String? currentUserId;
  String? jwtToken; // Store the token
  List<Future<User?>>? _driverFutures;

  // Define WSO2 coordinates (approximate for Colombo office)
  static const LatLng wso2Location = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadJwtToken(); // Load token asynchronously
    _initializeDriverFutures();
  }

  Future<void> _loadCurrentUserId() async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      Map<String, dynamic> payload;
      try {
        payload = Jwt.parseJwt(token);
      } catch (e) {
        await storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      if (Jwt.isExpired(token)) {
        await storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      setState(() {
        currentUserId = payload['id'];
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _loadJwtToken() async {
    final token = await storage.read(key: 'jwt_token');
    setState(() {
      jwtToken = token;
    });
  }

  void _initializeDriverFutures() {
    _driverFutures =
        widget.rides.map((ride) {
          final rideObject = Ride.fromJson(ride, ride['seat'] ?? 0);
          return _fetchDriverDetails(rideObject.driverId);
        }).toList();
  }

  Future<void> _bookRide(
    BuildContext context,
    String rideId,
    String waypoint,
    LatLng? waypointLatLng,
    double cost,
  ) async {
    final token = await storage.read(key: 'jwt_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No authentication token found. Please log in again.'),
        ),
      );
      return;
    }

    if (waypointLatLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waypoint location is not available.')),
      );
      return;
    }

    const String baseUrl = 'http://172.20.10.2:9090/api';
    final url = Uri.parse('$baseUrl/rides/book');
    final body = jsonEncode({
      'rideId': rideId,
      'waypoint': waypoint,
      'waypointLN': waypointLatLng,
      'cost': cost,
    });

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ride booked successfully!')),
      );
      final ride = widget.rides.firstWhere((r) => r['rideId'] == rideId);
      final driverToken = ride['driverToken'];
      if (driverToken != null) {
        await _sendNotificationToDriver(driverToken, rideId);
      }
      setState(() {}); // Refresh to update booked status
    } else {
      final errorMessage =
          jsonDecode(response.body)['message'] ?? 'Failed to book ride';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
    }
  }

  Future<double?> _calculateCost(
    double distance,
    String rideId,
    String token,
  ) async {
    const String baseUrl = 'http://172.20.10.2:9090/api';
    final url = Uri.parse('$baseUrl/rides/calculateCost');
    final body = jsonEncode({'rideId': rideId, 'distance': distance});

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['cost'] as double?;
      }
      return null;
    } catch (e) {
      print('Error calculating cost: $e');
      return null;
    }
  }

  double _calculateDistanceToRide(LatLng waypoint, bool waytowork) {
    if (waypoint == null) return 0.0; // Safety check

    // Calculate straight-line distance between waypoint and wso2Location
    double distance = _calculateDistance(
      waytowork ? waypoint : wso2Location,
      waytowork ? wso2Location : waypoint,
    );

    return distance / 1000; // Convert to kilometers
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    double lat1 = point1.latitude * math.pi / 180;
    double lat2 = point2.latitude * math.pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    double deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  double _calculateDistanceToWSO2(LatLng? waypoint) {
    if (waypoint == null) return 0.0; // Return 0 if waypoint is null
    return _calculateDistance(waypoint, wso2Location) /
        1000; // Convert to kilometers
  }

  Future<void> _sendNotificationToDriver(
    String driverToken,
    String rideId,
  ) async {
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
    const String serverKey = "shidGdj08HHsb_jDhBCR";

    final body = {
      'to': driverToken,
      'notification': {
        'title': 'New Ride Booking',
        'body':
            'A passenger has booked your ride (ID: $rideId) at ${currentDateTime.toString()}!',
      },
      'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'rideId': rideId},
    };

    final response = await http.post(
      Uri.parse(fcmUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  Future<User?> _fetchDriverDetails(String driverId) async {
    final token = await storage.read(key: 'jwt_token');
    if (token == null || driverId == null) return null;

    const String baseUrl = 'http://172.20.10.2:9090/api';
    final url = Uri.parse('$baseUrl/driver/$driverId');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData =
            data is Map<String, dynamic> && data.containsKey('User')
                ? data['User']
                : data;
        return User.fromJson(userData);
      }
      return null;
    } catch (e) {
      print('Error fetching driver details: $e');
      return null;
    }
  }

  bool _isRideBookedByCurrentUser(String rideId) {
    if (currentUserId == null) return false;

    final ride = widget.rides.firstWhere(
      (r) => r['rideId'] == rideId,
      orElse: () => {},
    );
    if (ride.isEmpty) return false;

    final seatCapacity = ride['seat'] as int? ?? 0;
    final passengers = Ride.fromJson(ride, seatCapacity).passengers;
    return passengers.any(
      (p) => p.passengerId == currentUserId && p.status == 'confirmed',
    );
  }

  Widget _getVehicleIcon(String? vehicleType) {
    switch (vehicleType?.toLowerCase()) {
      case 'sedan':
      case 'car':
        return const Icon(
          Icons.directions_car,
          size: 80,
          color: Colors.black87,
        );
      case 'suv':
        return const Icon(
          Icons.directions_car,
          size: 80,
          color: Colors.black87,
        );
      case 'van':
      case 'minivan':
        return Image.asset(
          'assets/van-icon.png',
          width: 80,
          height: 80,
          errorBuilder:
              (context, error, stackTrace) => const Icon(
                Icons.airport_shuttle,
                size: 80,
                color: Colors.black87,
              ),
        );
      case 'jeep':
        return Image.asset(
          'assets/jeep-icon.png',
          width: 80,
          height: 80,
          errorBuilder:
              (context, error, stackTrace) =>
                  const Icon(Icons.terrain, size: 40, color: Colors.black87),
        );
      default:
        return const Icon(
          Icons.directions_car,
          size: 80,
          color: Colors.black87,
        );
    }
  }

  String _formatTime(String time) {
    try {
      final parsedTime = DateTime.parse('2000-01-01 $time');
      return '${parsedTime.hour.toString().padLeft(2, '0')}.${parsedTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return time;
    }
  }

  String _formatDate(String date) {
    try {
      final parsedDate = DateTime.parse(date);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[parsedDate.month - 1]} ${parsedDate.day} ${parsedDate.year}';
    } catch (e) {
      return date;
    }
  }

  Widget _buildPlaceholderCard() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 1000),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 20, width: 100, color: Colors.grey[400]),
                  const SizedBox(height: 4),
                  Container(height: 16, width: 120, color: Colors.grey[400]),
                  Container(height: 16, width: 80, color: Colors.grey[400]),
                ],
              ),
              Container(height: 80, width: 80, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 24, width: 80, color: Colors.grey[400]),
              Container(height: 24, width: 80, color: Colors.grey[400]),
              Container(height: 32, width: 60, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(height: 40, width: 80, color: Colors.grey[400]),
              Container(height: 40, width: 120, color: Colors.grey[400]),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E2A),
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Column(
            children: [
              Text(
                widget.waytowork
                    ? 'WSO2'
                    : widget.waypoint.split(',').length > 1
                    ? widget.waypoint
                        .split(',')
                        .sublist(widget.waypoint.split(',').length - 2)
                        .join(',')
                    : widget.waypoint,
                style: const TextStyle(
                  color: companyColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDate(widget.date),
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ],
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0A0E2A),
      body:
          _driverFutures == null
              ? const Center(child: CircularProgressIndicator())
              : FutureBuilder<List<User?>>(
                future: Future.wait(_driverFutures!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: widget.rides.length,
                      itemBuilder: (context, index) => _buildPlaceholderCard(),
                    );
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading data'));
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.any((user) => user == null)) {
                    return const Center(child: Text('Some data is missing'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: widget.rides.length,
                    itemBuilder: (context, index) {
                      final ride = widget.rides[index];
                      final seatCapacity = ride['seat'] as int? ?? 0;
                      final rideObject = Ride.fromJson(ride, seatCapacity);
                      final driver = snapshot.data![index];
                      final rideId = rideObject.rideId;

                      final isBooked = _isRideBookedByCurrentUser(
                        rideObject.rideId,
                      );

                      return FutureBuilder<double?>(
                        future:
                            jwtToken == null
                                ? Future.value(0.0)
                                : _calculateCost(
                                  _calculateDistanceToRide(
                                    widget.waypointLatLng!,
                                    widget.waytowork,
                                  ),
                                  rideId,
                                  jwtToken!,
                                ),
                        builder: (context, costSnapshot) {
                          final cost = costSnapshot.data ?? 0.0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
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
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          driver != null
                                              ? '${driver.firstName} ${driver.lastName}'
                                              : 'Driver',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${driver?.driverDetails?.vehicleBrand} - ${driver?.driverDetails?.vehicleModel}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        Text(
                                          '${driver?.driverDetails?.vehicleRegistrationNumber}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                    _getVehicleIcon(
                                      driver?.driverDetails?.vehicleType,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            '${rideObject.passengers.length}/${driver?.driverDetails?.seatingCapacity ?? seatCapacity} seats',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => RideMapScreen(
                                                      ride: ride,
                                                      waypoint:
                                                          widget.waypointLatLng,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            'View route',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      _formatTime(rideObject.startTime),
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: ElevatedButton(
                                        onPressed:
                                            isBooked
                                                ? null
                                                : () => _bookRide(
                                                  context,
                                                  rideObject.rideId,
                                                  widget.waypoint,
                                                  widget.waypointLatLng,
                                                  cost,
                                                ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              isBooked
                                                  ? Colors.grey
                                                  : Colors.blue,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                        ),
                                        child: Text(
                                          isBooked ? 'Booked' : 'Book',
                                          style: const TextStyle(fontSize: 14),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Rs. ${cost.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton(
                                            onPressed:
                                                isBooked
                                                    ? null
                                                    : () {
                                                      // Disable when booked
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (
                                                                context,
                                                              ) => RideDetailsScreen(
                                                                ride:
                                                                    rideObject,
                                                                driver: driver,
                                                                cost: cost,
                                                              ),
                                                        ),
                                                      );
                                                    },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  isBooked
                                                      ? Colors.grey
                                                      : Colors.green,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 8,
                                                  ),
                                            ),
                                            child: const Text('More Details'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
    );
  }
}
