import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math' as math;

import 'package:mobile_frontend/views/driver/ride_cancel.dart';

class RideDetailScreen extends StatefulWidget {
  final Ride ride;

  const RideDetailScreen({super.key, required this.ride});

  @override
  _RideDetailScreenState createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  final storage = FlutterSecureStorage();
  List<Future<Map<String, dynamic>>>? _passengerFutures;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _initializePassengerFutures();
  }

  void _initializePassengerFutures() {
    _passengerFutures =
        widget.ride.passengers.map((passenger) {
          return _fetchPassengerDetails(passenger.passengerId);
        }).toList();
  }

  Future<Map<String, dynamic>> _fetchPassengerDetails(
    String passengerId,
  ) async {
    const String baseUrl = 'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0'; // Adjust IP as needed
    final url = Uri.parse('$baseUrl/passenger/$passengerId');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        return decodedResponse['User'] as Map<String, dynamic>? ?? {};
      }
      print(
        'Failed with status: ${response.statusCode}, body: ${response.body}',
      );
      return {};
    } catch (e) {
      print('Error fetching passenger details: $e');
      return {};
    }
  }

  Future<void> updateMapTheme(GoogleMapController controller) async {
    try {
      String styleJson = await getJsonFileFromThemes('themes/map_style.json');
      await controller.setMapStyle(styleJson);
    } catch (e) {
      debugPrint('Error setting map style: $e');
    }
  }

  Future<String> getJsonFileFromThemes(String path) async {
    return await rootBundle.loadString(path);
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
    return earthRadius * c / 1000; // Return in kilometers
  }

  List<Passenger> _sortPassengersByDistance(Ride ride) {
    LatLng startPoint = LatLng(
      6.8009,
      79.90088,
    ); // Placeholder: Moratuwa coordinates
    if (ride.passengers.isEmpty) return [];

    final passengersWithDistance =
        ride.passengers.map((passenger) {
          final distance = _calculateDistance(startPoint, passenger.waypoint);
          return (passenger: passenger, distance: distance);
        }).toList();

    passengersWithDistance.sort((a, b) => a.distance.compareTo(b.distance));
    return passengersWithDistance.map((item) => item.passenger).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sortedPassengers = _sortPassengersByDistance(widget.ride);
    final totalEarnings =
        widget.ride.passengers.isNotEmpty
            ? widget.ride.passengers.map((p) => p.cost).reduce((a, b) => a + b)
            : 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E2A),
        centerTitle: true,
        title: const Text(
          'Ride Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF0A0E2A),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // From Location Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'From:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ride.pickupLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // To Location Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'To:',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.ride.dropoffLocation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Seats Available Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Seats available',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(widget.ride.seat)} / ${widget.ride.seat+widget.ride.passengers.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Map Container
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    GoogleMap(
                      onMapCreated: (controller) {
                        _mapController = controller;
                        updateMapTheme(controller);
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          widget.ride.route.polyline.first.latitude,
                          widget.ride.route.polyline.first.longitude,
                        ),
                        zoom: 12,
                      ),
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: widget.ride.route.polyline,
                          color: Colors.blue,
                          width: 5,
                        ),
                      },
                      markers: {
                        Marker(
                          markerId: const MarkerId('start_point'),
                          position: widget.ride.route.polyline.first,
                          infoWindow: InfoWindow(
                            title: 'Start Point',
                            snippet: widget.ride.pickupLocation,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('end_point'),
                          position: widget.ride.route.polyline.last,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                          infoWindow: InfoWindow(
                            title: 'End Point',
                            snippet: widget.ride.dropoffLocation,
                          ),
                        ),
                        ...sortedPassengers.asMap().entries.map((entry) {
                          int index = entry.key;
                          var passenger = entry.value;
                          return Marker(
                            markerId: MarkerId(
                              'passenger_${passenger.passengerId}',
                            ),
                            position: passenger.waypoint,
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueBlue,
                            ),
                            infoWindow: InfoWindow(
                              title: 'Passenger ${index + 1}',
                              snippet: 'ID: ${passenger.passengerId}',
                            ),
                          );
                        }).toSet(),
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Passenger Details Section
            const Text(
              'Passengers:',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _passengerFutures == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<List<Map<String, dynamic>>>(
                  future: Future.wait(_passengerFutures!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Center(
                        child: Text('Error loading passengers'),
                      );
                    }

                    final passengerDetails = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedPassengers.length,
                      itemBuilder: (context, index) {
                        final passenger = sortedPassengers[index];
                        final details = passengerDetails[index];
                        final name =
                            '${details['firstName'] ?? 'Unknown'} ${details['lastName'] ?? ''}'
                                .trim();
                        final contact = details['phone'] ?? 'N/A';

                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E2749),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$name',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Location: ${passenger.address}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                '${passenger.waypoint.latitude}, ${passenger.waypoint.longitude}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Contact: $contact',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cost: Rs. ${passenger.cost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),

            // Start and Cancel Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SizedBox(
                  width: 140,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Start ride logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Start functionality to be implemented',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CancellationReasonScreen(ride: widget.ride),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Additional Ride Information
            ExpansionTile(
              title: const Text(
                'Additional Information',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white70,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2749),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Date', _formatDate(widget.ride.date)),
                      _buildInfoRow('Time', widget.ride.startTime),
                      _buildInfoRow('Duration', widget.ride.duration),
                      _buildInfoRow('Distance', '${widget.ride.distance} km'),
                      _buildInfoRow('Status', widget.ride.status),
                      _buildInfoRow(
                        'Earnings',
                        'Rs. ${totalEarnings.toStringAsFixed(2)}',
                      ),
                      _buildInfoRow(
                        'Passengers',
                        '${widget.ride.passengers.length}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
}
