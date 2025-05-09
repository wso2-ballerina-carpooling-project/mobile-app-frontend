import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideStartScreen extends StatefulWidget {
  const RideStartScreen({super.key});

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  Position? currentPositionOfUser;
  Set<Marker> markersSet = {};
  Set<Polyline> polylineSet = {};

  // Ride details
  final String driverName = "John Deo";
  final String vehicleNumber = "CBL 8090";
  final String vehicleModel = "Honda Civic";
  final int arrivalMinutes = 30;
  final String destinationLocation = "Welmilla";

  // Driver's position - will be updated periodically
  LatLng? driverPosition;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.8015, 79.9226), // Sri Lanka area as shown in screenshot
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    // Simulate driver movement
    _startDriverMovementSimulation();
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
          content: Text('Location permissions are permanently denied, please enable them in app settings'),
        ),
      );
      return;
    }
  }

  void _startDriverMovementSimulation() {
    // Initialize driver position near initial camera position
    driverPosition = LatLng(
      _initialCameraPosition.target.latitude - 0.005,
      _initialCameraPosition.target.longitude - 0.003,
    );
    
    // Update position every few seconds
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && driverPosition != null) {
        // Simulate driver movement towards destination
        setState(() {
          driverPosition = LatLng(
            driverPosition!.latitude + 0.0003, 
            driverPosition!.longitude + 0.0005
          );
        });
        _updateMap();
      }
    });
  }

  Future<void> _updateMap() async {
    if (driverPosition == null || controllerGoogleMap == null) return;
    
    try {
      // Get passenger position (user's current location)
      Position userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPositionOfUser = userPosition;
      
      LatLng passengerPosition = LatLng(
        currentPositionOfUser!.latitude,
        currentPositionOfUser!.longitude,
      );
      
      // Update markers and route
      _addMarkers(driverPosition!, passengerPosition);
      _drawPolylineFromOriginToDestination(driverPosition!, passengerPosition);

      // Keep the camera focused on driver's position
      CameraPosition cameraPosition = CameraPosition(
        target: driverPosition!,
        zoom: 15,
      );
      
      await controllerGoogleMap!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    } catch (e) {
      debugPrint('Error updating map: $e');
    }
  }

  Future<void> _drawPolylineFromOriginToDestination(LatLng driverPosition, LatLng passengerPosition) async {
    polylineSet.clear();
    
    // Create a more natural looking route
    final List<LatLng> polylineCoordinates = [
      driverPosition,
      LatLng(
        driverPosition.latitude + (passengerPosition.latitude - driverPosition.latitude) * 0.3,
        driverPosition.longitude + (passengerPosition.longitude - driverPosition.longitude) * 0.5,
      ),
      LatLng(
        driverPosition.latitude + (passengerPosition.latitude - driverPosition.latitude) * 0.7,
        driverPosition.longitude + (passengerPosition.longitude - driverPosition.longitude) * 0.6,
      ),
      passengerPosition,
    ];
    
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

  void _addMarkers(LatLng driverPosition, LatLng passengerPosition) {
    markersSet.clear();
    
    // Driver marker
    Marker driverMarker = Marker(
      markerId: const MarkerId("driver"),
      position: driverPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: "Driver", snippet: driverName),
    );
    
    // Passenger marker (pickup location)
    Marker passengerMarker = Marker(
      markerId: const MarkerId("passenger"),
      position: passengerPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: const InfoWindow(title: "Your Location", snippet: "Pickup point"),
    );
    
    setState(() {
      markersSet.add(driverMarker);
      markersSet.add(passengerMarker);
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
              _updateMap();
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
                  Navigator.of(context).pop();
                },
              ),
            ),
          ),
          
          // Driver info panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  // Destination and arrival time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        destinationLocation,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Arriving in $arrivalMinutes Mins',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getArrivalTime(arrivalMinutes),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Driver details - Restructured to match the design
                  Row(
                    children: [
                      // Driver profile image
                      const CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(
                          'https://via.placeholder.com/150', // Replace with actual driver image
                        ),
                      ),
                      const SizedBox(width: 15),
                      
                      // Driver name only
                      Text(
                        driverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      
                      // Spacer to push vehicle details to the right
                      const Spacer(),
                      
                      // Vehicle details placed on the right side
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            vehicleNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            vehicleModel,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Call button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.phone, color: Colors.black),
                          onPressed: () {
                            // Implement call functionality
                            debugPrint("Calling driver");
                          },
                        ),
                      ),
                      
                      const SizedBox(width: 12),
                      
                      // Message button
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[100],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.message, color: Colors.black),
                          onPressed: () {
                            // Implement message functionality
                            debugPrint("Messaging driver");
                          },
                        ),
                      ),
                    ],
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