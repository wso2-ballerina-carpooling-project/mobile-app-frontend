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
  bool showPickupDialog = false;

  // Ride details
  final String driverName = "John Wick";
  final int totalMinutes = 30;
  final int nextStopMinutes = 10;
  final int afterNextStopMinutes = 20;
  final String currentLocation = "Dissanayake Mawatha, Moratuwa";
  final String destinationLocation = "Bandaranayake Mawatha, Katubedda";
  final String passengerName = "Nalaka Dinesh"; // Added from the mockup

  // Location thresholds for triggering the popup
  final double arrivalThresholdMeters = 10.0; // Trigger popup when within this distance from pickup

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.8015, 79.9226), // Sri Lanka area as shown in screenshot
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
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
      LatLng pickupPosition = LatLng(userPosition.latitude, userPosition.longitude);
      
      // In a real app, you would compare the current position to the actual pickup location
      // For demonstration, we'll simulate arrival after a delay
      if (!showPickupDialog) {
        // Simulate arrival after 3 seconds for demonstration
        Future.delayed(const Duration(seconds: 3), () {
          setState(() {
            showPickupDialog = true;
          });
          _showPickupDialog();
        });
      }
      
      // In a real implementation, you would calculate the distance and check if it's below threshold:
      /*
      double distanceToPickup = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        pickupPosition.latitude,
        pickupPosition.longitude
      );
      
      if (distanceToPickup <= arrivalThresholdMeters && !showPickupDialog) {
        setState(() {
          showPickupDialog = true;
        });
        _showPickupDialog();
      }
      */
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
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  ),
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
      
      // Example destination for route drawing
      LatLng destinationPosition = LatLng(
        currentPositionOfUser!.latitude + 0.02, 
        currentPositionOfUser!.longitude + 0.02
      );
      
      // Add markers and draw route
      addMarkers(positionOfUserInLatLan, destinationPosition);
      drawPolylineFromOriginToDestination(positionOfUserInLatLan, destinationPosition);

      CameraPosition cameraPosition = CameraPosition(
        target: positionOfUserInLatLan,
        zoom: 15,
      );
      await controllerGoogleMap!.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> drawPolylineFromOriginToDestination(LatLng originPosition, LatLng destinationPosition) async {
    // In a real app, you'd implement actual routing API calls here
    // For demonstration, creating a simple route with waypoints
    
    polylineSet.clear();
    
    // Creating a simple route with intermediate points for a more natural look
    final List<LatLng> polylineCoordinates = [
      originPosition,
      LatLng(
        originPosition.latitude + (destinationPosition.latitude - originPosition.latitude) * 0.3,
        originPosition.longitude + (destinationPosition.longitude - originPosition.longitude) * 0.5,
      ),
      LatLng(
        originPosition.latitude + (destinationPosition.latitude - originPosition.latitude) * 0.7,
        originPosition.longitude + (destinationPosition.longitude - originPosition.longitude) * 0.6,
      ),
      destinationPosition,
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

  void addMarkers(LatLng pickupLocation, LatLng dropOffLocation) {
    markersSet.clear();
    
    // Current location marker
    Marker pickupMarker = Marker(
      markerId: const MarkerId("pickup"),
      position: pickupLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      infoWindow: InfoWindow(title: "Current Location", snippet: currentLocation),
    );
    
    // Destination marker
    Marker dropOffMarker = Marker(
      markerId: const MarkerId("dropoff"),
      position: dropOffLocation,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(title: "Destination", snippet: destinationLocation),
    );
    
    // Intermediate destination marker (next stop)
    Marker intermediateMarker = Marker(
      markerId: const MarkerId("intermediate"),
      position: LatLng(
        pickupLocation.latitude + (dropOffLocation.latitude - pickupLocation.latitude) * 0.6,
        pickupLocation.longitude + (dropOffLocation.longitude - pickupLocation.longitude) * 0.6,
      ),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      infoWindow: const InfoWindow(title: "Intermediate Stop", snippet: "Pickup another passenger"),
    );
    
    setState(() {
      markersSet.add(pickupMarker);
      markersSet.add(dropOffMarker);
      markersSet.add(intermediateMarker);
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
                        child: _buildStopInfoCard(
                          label: 'Next Stop',
                          minutes: nextStopMinutes,
                          driverName: driverName,
                        ),
                      ),
                      Expanded(
                        child: _buildStopInfoCard(
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
                        _buildLocationRow(
                          icon: Icons.my_location,
                          location: currentLocation,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 12),
                        _buildLocationRow(
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

  Widget _buildStopInfoCard({
    required String label,
    required int minutes,
    required String driverName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'In $minutes Mins',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Move profile image and name to be stacked vertically
              Column(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual driver image
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.phone, size: 20, color: Colors.blue),
              const SizedBox(width: 14),
              const Icon(Icons.message, size: 20, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required String location,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            location,
            style: const TextStyle(
              fontWeight: FontWeight.w500,  
              color: Colors.black54
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}