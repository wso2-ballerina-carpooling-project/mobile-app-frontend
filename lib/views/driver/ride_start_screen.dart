import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:ui' as ui;
import 'dart:math' show atan2, pi;

import 'package:mobile_frontend/widgets/Map_Related/LocationRow.dart';
import 'package:mobile_frontend/widgets/Map_Related/StopInfoCard.dart';

class RideStartScreen extends StatefulWidget {
  const RideStartScreen({super.key});

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {

  BitmapDescriptor? carIcon;
  Marker? vehicleMarker;
  Timer? locationUpdateTimer;
  int markerRotation = 0;
  LatLng? previousPosition;

  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  Position? currentPositionOfUser;
  Set<Marker> markersSet = {};
  Set<Polyline> polylineSet = {};
  List<LatLng> polylineCoordinates = [];
  bool showPickupDialog = false;

  // Ride details
  final String driverName = "John Wick";
  final int totalMinutes = 30;
  final int nextStopMinutes = 10;
  final int afterNextStopMinutes = 20;
  final String currentLocation = "Dissanayake Mawatha, Moratuwa";
  final String destinationLocation = "Bandaranayake Mawatha, Katubedda";
  final String passengerName = "Nalaka Dinesh";

  final double arrivalThresholdMeters = 10.0;

  // Google Directions API key 
  final String googleAPIKey = "AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE";

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.8015, 79.9226), // Sri Lanka area
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _createCarMarkerIcon();
  }

  @override
  void dispose() {
    // Cancel timer when screen is disposed
    locationUpdateTimer?.cancel();
    super.dispose();
  }


  Future<void> _createCarMarkerIcon() async {
    try {
      // You can either use a local asset or create a bitmap from a flutter icon
      // Option 1: From local asset
      final Uint8List markerIcon = await _getBytesFromAsset('assets/car_icon.png', 80);
      setState(() {
        carIcon = BitmapDescriptor.fromBytes(markerIcon);
      });
      
      // Option 2: If you don't have an asset, use default marker temporarily
      if (carIcon == null) {
        carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
      }
    } catch (e) {
      debugPrint('Error creating car icon: $e');
      // Fallback to default marker
      carIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    }
  }
  
  // Convert asset image to bytes
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
  
   void startLocationUpdates() {
    // Cancel any existing timer
    locationUpdateTimer?.cancel();
    
    // Define update frequency (e.g., every 3 seconds)
    locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateDriverLocation();
    });
  }

  Future<void> _updateDriverLocation() async {
    try {
      // Option 1: Get real GPS location (for actual driver app)
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newLocation = LatLng(currentPosition.latitude, currentPosition.longitude);
      
      // Option 2: For testing - simulate movement along the polyline
      // LatLng newLocation = _getNextPointOnRoute();
      
      // Calculate bearing for vehicle rotation if we have a previous position
      if (previousPosition != null) {
        markerRotation = _calculateRotation(previousPosition!, newLocation);
      }
      
      _updateVehicleMarker(newLocation);
      previousPosition = newLocation;
      
      // Check if driver is close to waypoint for notifications
      _checkProximityToWaypoints(newLocation);
      
    } catch (e) {
      debugPrint('Error updating location: $e');
    }
  }
  
   void _updateVehicleMarker(LatLng newLocation) {
    if (carIcon != null) {
      setState(() {
        vehicleMarker = Marker(
          markerId: const MarkerId('vehicle'),
          position: newLocation,
          icon: carIcon!,
          rotation: markerRotation.toDouble(), // Rotate marker according to movement direction
          anchor: const Offset(0.5, 0.5), // Center the icon
          flat: true, // Make it flat against the map
          zIndex: 2, // Ensure it's above the route line
        );
        
        // Add the vehicle marker to the marker set
        markersSet.removeWhere((marker) => marker.markerId.value == 'vehicle');
        markersSet.add(vehicleMarker!);
      });
      
      // Move camera to follow the vehicle if needed
      _followVehicle(newLocation);
    }
  }

    int _calculateRotation(LatLng previous, LatLng current) {
    double deltaLng = current.longitude - previous.longitude;
    double deltaLat = current.latitude - previous.latitude;
    double rotation = atan2(deltaLng, deltaLat) * 180 / pi;
    return rotation.round();
  }
  
  // Move camera to follow the vehicle
  void _followVehicle(LatLng position) {
    if (controllerGoogleMap != null) {
      controllerGoogleMap!.animateCamera(
        CameraUpdate.newLatLng(position),
      );
    }
  }
  
  // Check if driver is near any waypoint to show notifications
  void _checkProximityToWaypoints(LatLng driverLocation) {
    // Get your list of waypoints
    List<LatLng> waypoints = polylineCoordinates.isEmpty 
        ? [] 
        : [for (LatLng point in polylineCoordinates) if (_isWaypoint(point)) point];
    
    for (LatLng waypoint in waypoints) {
      double distanceToWaypoint = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        waypoint.latitude,
        waypoint.longitude,
      );
      
      // If driver is within 50 meters of waypoint
      if (distanceToWaypoint <= 50) {
        // Show notification or update UI
        _showWaypointApproachingNotification(waypoint);
        break;
      }
    }
  }
  
  // Helper to determine if a point is a waypoint (not just a route point)
  bool _isWaypoint(LatLng point) {
    // Check if this point matches any of your defined waypoints
    // This is a simplified example - you may need a more robust approach
    for (Marker marker in markersSet) {
      if (marker.position.latitude == point.latitude && 
          marker.position.longitude == point.longitude &&
          marker.markerId.value.contains('waypoint')) {
        return true;
      }
    }
    return false;
  }
  
  // Show notification when approaching waypoint
  void _showWaypointApproachingNotification(LatLng waypoint) {
    // Find which waypoint this is
    String waypointName = "Waypoint";
    for (Marker marker in markersSet) {
      if (marker.position.latitude == waypoint.latitude && 
          marker.position.longitude == waypoint.longitude) {
        waypointName = marker.infoWindow.title ?? "Waypoint";
        break;
      }
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Approaching $waypointName'),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
      ),
    );
  }


  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permissions are denied')),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permissions are permanently denied, please enable them in app settings',
          ),
        ),
      );
      return;
    }

    // Start a periodic location check to simulate driver arriving at pickup
    Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkIfArrivedAtPickup();
    });
  }

  Future<void> _checkIfArrivedAtPickup() async {
    try {
      // Get current position
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get pickup location (for demonstration, we're using the marker position)
      LatLng pickupPosition = LatLng(
        userPosition.latitude,
        userPosition.longitude,
      );

      // In a real app, you would compare the current position to the actual pickup location
      // For demonstration, we'll simulate arrival after a delay
      // if (!showPickupDialog) {
      //   // Simulate arrival after 3 seconds for demonstration
      //   Future.delayed(const Duration(seconds: 3), () {
      //     setState(() {
      //       showPickupDialog = true;
      //     });
      //     _showPickupDialog();
      //   });
      // }

      // In a real implementation, you would calculate the distance and check if it's below threshold:

      double distanceToPickup = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        pickupPosition.latitude,
        pickupPosition.longitude,
      );

      if (distanceToPickup <= arrivalThresholdMeters && !showPickupDialog) {
        setState(() {
          showPickupDialog = true;
        });
        _showPickupDialog();
      }
    } catch (e) {
      debugPrint('Error checking arrival: $e');
    }
  }

  void _showPickupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'You arrived to pickup location',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Passenger Details',
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(height: 15),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: const NetworkImage(
                    'https://via.placeholder.com/150', // Replace with actual passenger image
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  passengerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.phone, color: Colors.black),
                        onPressed: () {
                          // Implement call functionality
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Implement pickup confirmation logic
                  },
                  child: const Text(
                    'Picked',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> getCurrentLiveLocationOfUser() async {
  try {
    Position positionOfUser = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    currentPositionOfUser = positionOfUser;
    LatLng positionOfUserInLatLan = LatLng(
      currentPositionOfUser!.latitude,
      currentPositionOfUser!.longitude,
    );

    // Define multiple waypoints for the route
    List<LatLng> waypointsList = [
      LatLng(6.795761, 79.898232),  // First intermediate position
      LatLng(6.795019, 79.900715),  // Second intermediate position
    ];
    
    // Final destination
    LatLng destinationPosition = LatLng(6.792993, 79.900808);

    // Add markers for each waypoint and the destination
    addMarkers(waypointsList, destinationPosition);

    // Draw route with multiple waypoints using Google Directions API
    await getDirectionsWithWaypoints(
      positionOfUserInLatLan, 
      waypointsList,
      destinationPosition
    );

     previousPosition = positionOfUserInLatLan;
      _updateVehicleMarker(positionOfUserInLatLan);

       startLocationUpdates();
    // Move camera to user's current position
    CameraPosition cameraPosition = CameraPosition(
      target: positionOfUserInLatLan,
      zoom: 15,
    );
    await controllerGoogleMap!.animateCamera(
      CameraUpdate.newCameraPosition(cameraPosition),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error getting location: $e'))
    );
  }
}

  // Get directions from Google API that follow actual roads
  Future<void> getDirectionsWithWaypoints(
    LatLng origin,
    List<LatLng> waypoints,
    LatLng destination,
  ) async {
    try {
      // Prepare waypoints string for the API
      String waypointsString = "";
      if (waypoints.isNotEmpty) {
        waypointsString = "&waypoints=";
        for (int i = 0; i < waypoints.length; i++) {
          if (i > 0) waypointsString += "|";
          waypointsString +=
              "${waypoints[i].latitude},${waypoints[i].longitude}";
        }
      }

      // Google Directions API URL
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${origin.latitude},${origin.longitude}"
          "&destination=${destination.latitude},${destination.longitude}"
          "$waypointsString"
          "&key=$googleAPIKey"
          "&mode=driving"; // Specify driving mode to follow roads

      var response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);

        // Check if the API returned routes
        if (decodedData["status"] == "OK") {
          _decodePoints(decodedData);
        } else {
          debugPrint("Directions API error: ${decodedData["status"]}");
          // Fallback to simple route if API fails
          drawSimplePolyline(origin, destination, waypoints);
        }
      } else {
        debugPrint("Failed to get directions: ${response.statusCode}");
        // Fallback to simple route if API call fails
        drawSimplePolyline(origin, destination, waypoints);
      }
    } catch (e) {
      debugPrint("Error getting directions: $e");
      // Fallback to simple route in case of errors
      drawSimplePolyline(origin, destination, waypoints);
    }
  }

  // Decode the route points from Google Directions API response
  void _decodePoints(Map<String, dynamic> directionDetails) {
    polylineCoordinates.clear();

    if (directionDetails["routes"].isEmpty) return;

    // Extract all the points
    List<dynamic> routes = directionDetails["routes"];

    // Extract the route
    Map<String, dynamic> route = routes[0];

    // Extract the legs - each leg is a section of the journey
    List<dynamic> legs = route["legs"];

    // Loop through all legs and steps
    for (var leg in legs) {
      List<dynamic> steps = leg["steps"];

      for (var step in steps) {
        String polyline = step["polyline"]["points"];
        List<LatLng> decodedPolylinePoints = _decodePolyline(polyline);
        polylineCoordinates.addAll(decodedPolylinePoints);
      }
    }

    // Create the polyline with the route points
    _createPolyline();
  }

  // Algorithm to decode Google's polyline format
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

      LatLng position = LatLng(finalLat, finalLng);
      poly.add(position);
    }

    return poly;
  }

  // Create the polyline from coordinates
  void _createPolyline() {
    polylineSet.clear();

    Polyline polyline = Polyline(
      polylineId: const PolylineId("route"),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
      jointType: JointType.round,
    );

    setState(() {
      polylineSet.add(polyline);
    });
  }

  // Fallback method in case the Directions API call fails
  void drawSimplePolyline(
    LatLng origin,
    LatLng destination,
    List<LatLng> waypoints,
  ) {
    polylineCoordinates.clear();
    polylineSet.clear();

    // Add origin
    polylineCoordinates.add(origin);

    // Add waypoints
    for (var waypoint in waypoints) {
      polylineCoordinates.add(waypoint);
    }

    // Add destination
    polylineCoordinates.add(destination);

    // Create the polyline
    _createPolyline();
  }

  void addMarkers(List<LatLng> waypoints, LatLng dropOffLocation) {
  markersSet.clear();

  // Current location marker is handled by myLocationEnabled: true in GoogleMap widget

  // Add waypoint markers
  for (int i = 0; i < waypoints.length; i++) {
    Marker waypointMarker = Marker(
      markerId: MarkerId("waypoint_$i"),
      position: waypoints[i],
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: InfoWindow(
        title: "Waypoint ${i + 1}",
        snippet: "Intermediate stop",
      ),
    );
    
    setState(() {
      markersSet.add(waypointMarker);
    });
  }

  // Add destination marker
  Marker dropOffMarker = Marker(
    markerId: const MarkerId("dropoff"),
    position: dropOffLocation,
    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
    infoWindow: InfoWindow(
      title: "Destination",
      snippet: destinationLocation,
    ),
  );

  setState(() {
    markersSet.add(dropOffMarker);
  });
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

  String _getArrivalTime(int minutesFromNow) {
    final now = DateTime.now();
    final arrivalTime = now.add(Duration(minutes: minutesFromNow));

    // Format time without using intl package
    int hour = arrivalTime.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour > 12 ? hour - 12 : hour;
    hour = hour == 0 ? 12 : hour;
    final minute = arrivalTime.minute.toString().padLeft(2, '0');

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            mapType: MapType.normal,
            myLocationEnabled: true,
            zoomControlsEnabled: false,
            myLocationButtonEnabled: false,
            initialCameraPosition: _initialCameraPosition,
            markers: markersSet,
            polylines: polylineSet,
            onMapCreated: (GoogleMapController controller) {
              googleMapCompleterController.complete(controller);
              controllerGoogleMap = controller;
              updateMapTheme(controller);
              getCurrentLiveLocationOfUser();
            },
          ),

          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/main');
                },
              ),
            ),
          ),

          // Arrival info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arrival time
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Arriving in $totalMinutes Mins',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          _getArrivalTime(totalMinutes),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Stops info
                  Row(
                    children: [
                      Expanded(
                        child: StopInfoCard(
                          label: 'Next Stop',
                          minutes: nextStopMinutes,
                          driverName: driverName,
                        ),
                      ),
                      Expanded(
                        child: StopInfoCard(
                          label: 'After Next',
                          minutes: afterNextStopMinutes,
                          driverName: driverName,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Location details
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        LocationRow(
                          icon: Icons.my_location,
                          location: currentLocation,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 12),
                        LocationRow(
                          icon: Icons.location_on,
                          location: destinationLocation,
                          color: Colors.deepOrange,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  

 
}
