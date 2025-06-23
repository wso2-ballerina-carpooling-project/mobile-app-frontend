import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PassengerRideTracking extends StatefulWidget {
  const PassengerRideTracking({super.key});

  @override
  State<PassengerRideTracking> createState() => _PassengerRideTrackingState();
}

class _PassengerRideTrackingState extends State<PassengerRideTracking> {
  final Completer<GoogleMapController> googleMapCompleterController =
      Completer<GoogleMapController>();
  GoogleMapController? controllerGoogleMap;

  Position? currentPositionOfUser;
  Set<Marker> markersSet = {};
  Set<Polyline> polylineSet = {};

  // Ride details
  final String driverName = "John Doe";
  final String vehicleNumber = "CBL 8090";
  final String vehicleModel = "Honda Civic";
  final int arrivalMinutes = 30;
  

  // Driver's position - will be updated periodically
  LatLng? driverPosition;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.8015, 79.9226), // Sri Lanka area 
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
          
          // Driver info panel - shorter to show map underneath
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.only(bottom: 10),
              height: 230, // Reduced height to show map underneath
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    spreadRadius: 2,
                    blurRadius: 12,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Destination header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Destination location
                        // Text(
                        //   destinationLocation,
                        //   style: const TextStyle(
                        //     fontSize: 20,
                        //     fontWeight: FontWeight.bold,
                        //   ),
                        // ),
                        
                        const SizedBox(height: 5),
                        
                        // Arriving info row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Arriving in text with green minutes
                            RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                                children: [
                                  const TextSpan(text: 'Arriving in '),
                                  TextSpan(
                                    text: '$arrivalMinutes Mins',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Time on right
                            Text(
                              _getArrivalTime(arrivalMinutes),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  
                  // Driver and vehicle details
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 5, 20, 5),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Driver profile image with name below
                        Column(
                          children: [
                            const CircleAvatar(
                              radius: 28,
                              backgroundImage: NetworkImage(
                                'https://i.pravatar.cc/150?img=33', // Replace with actual driver image
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              driverName,
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        // Spacer to push vehicle details to the right
                        const Spacer(),
                        
                        // Vehicle details and call/message buttons
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Vehicle details - number bold and model below
                            Text(
                              vehicleNumber,
                               
                              style: const TextStyle(
                                color: Color.fromARGB(255, 0, 0, 0),
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                            Text(
                              vehicleModel,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Call and message buttons row
                            Row(
                              children: [
                                // Call button
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () {
                                        // Implement call functionality
                                        debugPrint("Calling driver");
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          Icons.phone,
                                          color: Colors.grey[800],
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                
                                const SizedBox(width: 15),
                                
                                // Message button
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey[200],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () {
                                        // Implement message functionality
                                        debugPrint("Messaging driver");
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12.0),
                                        child: Icon(
                                          Icons.message,
                                          color: Colors.grey[800],
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
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