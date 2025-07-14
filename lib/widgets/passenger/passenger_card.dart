import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';

class PassengerRideCard extends StatefulWidget {
  final Ride ride;

  const PassengerRideCard({super.key, required this.ride});

  @override
  State<PassengerRideCard> createState() => _PassengerRideCardState();
}

class _PassengerRideCardState extends State<PassengerRideCard> {
  late GoogleMapController mapController;
  late Set<Marker> markers;
  late Set<Polyline> polylines;

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
  void initState() {
    super.initState();
    _initializeMapData();
  }

  void _initializeMapData() {
    final points = widget.ride.route.polyline;
    final waypoints = widget.ride.passengers.map((p) => p.waypoint).toList();

    markers = {
      Marker(
        markerId: const MarkerId('start'),
        position:
            points.isNotEmpty ? points.first : const LatLng(6.9271, 79.8612),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: 'Pickup: ${widget.ride.pickupLocation}'),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position:
            points.isNotEmpty ? points.last : const LatLng(6.9271, 79.8612),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(
          title: 'Dropoff: ${widget.ride.dropoffLocation}',
        ),
      ),
      ...waypoints
          .asMap()
          .entries
          .map((entry) {
            final index = entry.key;
            final waypoint = entry.value;
            if (waypoint != null && index + 1 < points.length) {
              return Marker(
                markerId: MarkerId('waypoint_$index'),
                position: points[index + 1],
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueOrange,
                ),
                infoWindow: InfoWindow(title: 'Waypoint: $waypoint'),
              );
            }
            return const Marker(
              markerId: MarkerId('empty'),
              position: LatLng(0, 0),
            );
          })
          .where((m) => m.position.latitude != 0),
    };

    polylines = {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 2,
      ),
    };
  }

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startLocation = widget.ride.pickupLocation;
    final endLocation = widget.ride.dropoffLocation;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 2.0),
      color: const Color(0xFFf1f3f4),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              startLocation,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              endLocation,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cost: Rs. 300', // Placeholder cost value for passengers
                  style: TextStyle(fontSize: 16, color: Colors.green[700]),
                ),
                Text(
                  'Driver ID: ${widget.ride.driverId}',
                  style: const TextStyle(fontSize: 16, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  updateMapTheme(controller);
                },
                initialCameraPosition: CameraPosition(
                  target:
                      widget.ride.route.polyline.isNotEmpty
                          ? widget.ride.route.polyline[0]
                          : const LatLng(6.9271, 79.8612),
                  zoom: 12.0,
                ),
                markers: markers,
                polylines: polylines,
                mapType: MapType.normal,
                minMaxZoomPreference: const MinMaxZoomPreference(10.0, 18.0),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'View More',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
