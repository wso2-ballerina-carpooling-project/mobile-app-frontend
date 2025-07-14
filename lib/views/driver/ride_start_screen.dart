import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/models/RideData.dart';

class DriverRideTracking extends StatefulWidget {
  final Ride ride;
  const DriverRideTracking({super.key, required this.ride});

  @override
  State<DriverRideTracking> createState() => _DriverRideTrackingState();
}

class _DriverRideTrackingState extends State<DriverRideTracking> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Position? currentPosition;
  bool isLoading = true;
  Timer? locationUpdateTimer;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _fetchDrivingRoute(
      widget.ride.route.polyline.first,
      widget.ride.route.polyline.last,
    );
  }

  @override
  void dispose() {
    locationUpdateTimer?.cancel();
    mapController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied');
      return;
    }
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    _getCurrentLocation();
    locationUpdateTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateDriverLocation();
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPosition = position;
        _addDriverMarker(LatLng(position.latitude, position.longitude));
        isLoading = false;
      });
      await _fetchDrivingRoute(
        LatLng(position.latitude, position.longitude),
        widget.ride.route.polyline.last,
      );
    } catch (e) {
      _showError('Error getting location: $e');
    }
  }

  Future<void> _updateDriverLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newPosition = LatLng(position.latitude, position.longitude);
      setState(() {
        currentPosition = position;
        _addDriverMarker(newPosition);
      });
      await _fetchDrivingRoute(newPosition, widget.ride.route.polyline.last);
      _animateCameraToPosition(newPosition);
    } catch (e) {
      _showError('Error updating location: $e');
    }
  }

  Future<void> _fetchDrivingRoute(LatLng origin, LatLng destination) async {
    try {
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&mode=driving&key=AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE";

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        if (decodedData["status"] == "OK") {
          _decodePoints(decodedData);
        } else {
          _showError('Failed to fetch driving route: ${decodedData["status"]}');
        }
      } else {
        _showError('Failed to get directions: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error getting directions: $e');
    }
  }

  void _decodePoints(Map<String, dynamic> directionDetails) {
    polylineCoordinates.clear();
    if (directionDetails["routes"].isEmpty) {
      _showError('No routes found for the given locations');
      return;
    }

    List<dynamic> routes = directionDetails["routes"];
    Map<String, dynamic> route = routes[0];
    List<dynamic> legs = route["legs"];

    for (var leg in legs) {
      List<dynamic> steps = leg["steps"];
      for (var step in steps) {
        String polyline = step["polyline"]["points"];
        List<LatLng> decodedPolylinePoints = _decodePolyline(polyline);
        polylineCoordinates.addAll(decodedPolylinePoints);
      }
    }
    _createPolyline();
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      double finalLat = lat / 1E5;
      double finalLng = lng / 1E5;
      poly.add(LatLng(finalLat, finalLng));
    }
    return poly;
  }

  void _createPolyline() {
    polylines.clear();
    if (polylineCoordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId("route"),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
          jointType: JointType.round,
        ),
      );
      setState(() {});
    }
  }

  void _addDriverMarker(LatLng position) {
    markers.clear();
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('start'),
        position: widget.ride.route.polyline.first,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: widget.ride.pickupLocation),
      ),
    );
    markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: widget.ride.route.polyline.last,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: widget.ride.dropoffLocation),
      ),
    );
    setState(() {});
  }

  void _animateCameraToPosition(LatLng position) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 14.0),
      duration: const Duration(milliseconds: 500),
    );
  }

  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // meters
    final lat1 = point1.latitude * pi / 180;
    final lat2 = point2.latitude * pi / 180;
    final deltaLat = (point2.latitude - point1.latitude) * pi / 180;
    final deltaLon = (point2.longitude - point1.longitude) * pi / 180;

    final a =
        sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Ride Tracking')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: currentPosition != null
                    ? LatLng(currentPosition!.latitude, currentPosition!.longitude)
                    : widget.ride.route.polyline.first,
                zoom: 12,
              ),
              markers: markers,
              polylines: polylines,
              myLocationEnabled: true,
            ),
    );
  }
}