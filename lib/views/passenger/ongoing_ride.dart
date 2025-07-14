import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/models/user.dart';

class OngoingRide extends StatelessWidget {
  final Ride ride;
  final User? driver;
  final double cost;

  const OngoingRide({
    Key? key,
    required this.ride,
    required this.driver,
    required this.cost,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
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
            // Driver Profile Section
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: const AssetImage(
                      'assets/placeholder_profile.png',
                    ),
                    onBackgroundImageError: (exception, stackTrace) {
                      // Handle error if placeholder image fails to load
                    },
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${driver?.firstName ?? 'Unknown'} ${driver?.lastName ?? ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Information Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2749),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${driver?.driverDetails?.vehicleBrand ?? 'Unknown'} ${driver?.driverDetails?.vehicleModel ?? ''} - ${driver?.driverDetails?.vehicleRegistrationNumber ?? 'N/A'}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

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
                    ride.pickupLocation,
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
                    ride.dropoffLocation,
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
                    '${(driver?.driverDetails?.seatingCapacity ?? ride.seat) - ride.passengers.length} / ${driver?.driverDetails?.seatingCapacity ?? ride.seat}',
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

            // Map Container (Placeholder)
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
                    // Map placeholder - you can replace this with actual map widget
                    Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[300],
                      child: const Center(
                        child: Text(
                          'Map View\n(Route Preview)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      ),
                    ),
                    // If you have Google Maps integration, you can use:
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        updateMapTheme(controller);
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          ride.route.polyline.first.latitude,
                          ride.route.polyline.first.longitude,
                        ),
                        zoom: 12,
                      ),
                      polylines: {
                        Polyline(
                          polylineId: const PolylineId('route'),
                          points: ride.route.polyline,

                          color: Colors.blue,
                          width: 5,
                        ),
                      },

                      markers: {
                        Marker(
                          markerId: const MarkerId("Start Point"),
                          position: ride.route.polyline.first,
                          infoWindow: InfoWindow(
                            title: 'Start Point',
                            snippet: ride.pickupLocation,
                          ),
                        ),
                        Marker(
                          markerId: const MarkerId('end_point'),
                          position: ride.route.polyline.last,
                          icon: BitmapDescriptor.defaultMarkerWithHue(
                            BitmapDescriptor.hueRed,
                          ),
                          infoWindow: InfoWindow(
                            title: 'End Point',
                            snippet: ride.dropoffLocation,
                          ),
                        ),
                        ...ride.passengers.asMap().entries.map((entry) {
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
                              snippet: 'Passenger ID: ${passenger.passengerId}',
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

            // Book Now Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // Add booking logic here
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking functionality to be implemented'),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional ride information (collapsed by default)
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
                      _buildInfoRow('Date', _formatDate(ride.date)),
                      _buildInfoRow('Time', ride.startTime),
                      _buildInfoRow('Duration', ride.duration),
                      _buildInfoRow('Distance', '${ride.distance} km'),
                      _buildInfoRow('Status', ride.status),
                      _buildInfoRow('Cost', 'Rs. ${cost.toStringAsFixed(2)}'),
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
