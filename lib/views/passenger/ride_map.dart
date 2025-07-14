import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class RideMapScreen extends StatefulWidget {
  final Map<String, dynamic> ride;
  final LatLng? waypoint; // Nullable LatLng

  const RideMapScreen({Key? key, required this.ride, required this.waypoint})
      : super(key: key);

  @override
  State<RideMapScreen> createState() => _RideMapScreenState();
}

class _RideMapScreenState extends State<RideMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _initializeMap();
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

  Future<void> _initializeMap() async {
    try {
      // Check if waypoint is null
      if (widget.waypoint == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waypoint location is not available.')),
        );
        return;
      }

      // Proceed only if waypoint is not null
      final LatLng waypoint = widget.waypoint!; // Use non-null assertion since we checked

      // Create marker for pickup location
      setState(() {
        _markers.add(
          Marker(
            markerId: const MarkerId('pickup'),
            position: waypoint,
            infoWindow: InfoWindow(title: 'Pickup: ${waypoint.latitude}, ${waypoint.longitude}'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
        );
      });

      // Extract polyline from ride
      List<dynamic> polylineData = widget.ride['route']['polyline'];
      List<LatLng> polylinePoints = polylineData
          .map((point) {
            try {
              return LatLng(
                double.parse(point['latitude'].toString()),
                double.parse(point['longitude'].toString()),
              );
            } catch (e) {
              print('Error parsing polyline point: $point, error: $e');
              return LatLng(0, 0);
            }
          })
          .where((point) => point.latitude != 0 && point.longitude != 0)
          .toList();

      if (polylinePoints.isNotEmpty) {
        setState(() {
          _polylines.add(
            Polyline(
              polylineId: PolylineId(widget.ride['rideId']),
              points: polylinePoints,
              color: Colors.blue,
              width: 5,
            ),
          );
        });

        // Adjust camera to fit polyline and pickup marker
        LatLngBounds bounds = _calculateBounds([
          ...polylinePoints,
          waypoint, // Use the non-null waypoint
        ]);
        _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
      }
    } catch (e) {
      print('Error initializing map: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading map: $e')));
    }
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double south = points[0].latitude;
    double north = points[0].latitude;
    double west = points[0].longitude;
    double east = points[0].longitude;

    for (var point in points) {
      if (point.latitude < south) south = point.latitude;
      if (point.latitude > north) north = point.latitude;
      if (point.longitude < west) west = point.longitude;
      if (point.longitude > east) east = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E2A),
        title: const Text('Ride Route', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: const CameraPosition(
          target: LatLng(6.8953284, 79.8546711), // WSO2 coordinates as fallback
          zoom: 14.0,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (GoogleMapController controller) {
          _mapController = controller;
           updateMapTheme(controller);
          // Trigger camera adjustment after map is created
          _initializeMap();
        },
      ),
    );
  }
}