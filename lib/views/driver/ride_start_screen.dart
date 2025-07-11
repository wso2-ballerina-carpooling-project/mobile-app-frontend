import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/models/RideData.dart';
import 'package:mobile_frontend/widgets/Map_Related/LocationRow.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class RideStartScreen extends StatefulWidget {
  final String rideId;
  const RideStartScreen({super.key, required this.rideId});

  @override
  State<RideStartScreen> createState() => _RideStartScreenState();
}

class _RideStartScreenState extends State<RideStartScreen> {
  final _storage = FlutterSecureStorage();
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  bool _isWebSocketConnected = false;
  final String _webSocketUrl = 'ws://10.0.2.2:8080/ws';

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
  bool isLoading = true;
  Ride? rideData;
  List<Passenger> unvisitedPassengers = [];
  String? currentPassengerId;
  bool rideEnded = false;
  Map<String, dynamic> passengerDetails = {};
  Map<String, String> waypointAddresses =
      {}; // Cache for reverse-geocoded addresses

  final double arrivalThresholdMeters = 50.0;
  final String googleAPIKey = "AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE";

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(6.8015, 79.9226),
    zoom: 14.4746,
  );

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _createCarMarkerIcon();
    _initializeWebSocket();
    _fetchRideData();
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _closeWebSocket();
    locationUpdateTimer?.cancel();
    controllerGoogleMap?.dispose();
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

  Future<void> _fetchRideData() async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showError('Authentication token not found. Please log in again.');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://172.20.10.2:9090/api/getStartRide'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'rideId': widget.rideId}),
      );
      print(response.statusCode);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['rides'] != null &&
            data['rides'] is List &&
            data['rides'].isNotEmpty) {
          setState(() {
            rideData = Ride.fromJson(
              data['rides'][0],
              4,
            ); // Assume seatingCapacity=4
            unvisitedPassengers = List.from(rideData!.passengers);
            isLoading = false;
          });
          // Fetch passenger details and addresses
          for (var passenger in unvisitedPassengers) {
            // _fetchPassengerDetails(passenger.passengerId);
            _fetchWaypointAddress(passenger.passengerId, passenger.waypoint);
          }
          await _initializeRoute();
        } else {
          _showError('Invalid ride data received from server');
        }
      } else {
        _showError(
          'Failed to fetch ride data: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      _showError('Error fetching ride data: $e');
    }
  }

  Future<void> _fetchWaypointAddress(
    String passengerId,
    LatLng waypoint,
  ) async {
    if (waypointAddresses[passengerId] != null) return;
    try {
      final address = await _reverseGeocode(waypoint);
      setState(() {
        waypointAddresses[passengerId] = address;
      });
    } catch (e) {
      setState(() {
        waypointAddresses[passengerId] =
            '${waypoint.latitude}, ${waypoint.longitude}';
      });
    }
  }

  Future<String> _reverseGeocode(LatLng coords) async {
    final response = await http.get(
      Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=${coords.latitude},${coords.longitude}&key=$googleAPIKey',
      ),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['results'][0]['formatted_address'] ??
          '${coords.latitude}, ${coords.longitude}';
    }
    return '${coords.latitude}, ${coords.longitude}';
  }

  Future<void> _initializeRoute() async {
    if (rideData == null || currentPositionOfUser == null) return;

    setState(() {
      polylineCoordinates = List.from(rideData!.route.polyline);
      _createPolyline();
    });

    await getCurrentLiveLocationOfUser();
    await _updateNearestPassenger();
  }

  Future<void> _updateNearestPassenger() async {
    if (rideData == null ||
        currentPositionOfUser == null ||
        unvisitedPassengers.isEmpty) {
      setState(() {
        currentPassengerId = null;
      });
      if (unvisitedPassengers.isEmpty && !rideEnded) {
        final endLocation = rideData!.route.polyline.last;
        await getDirectionsWithWaypoints(
          LatLng(
            currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude,
          ),
          [],
          endLocation,
        );
        _addDestinationMarker(endLocation);
        if (_calculateDistance(
              LatLng(
                currentPositionOfUser!.latitude,
                currentPositionOfUser!.longitude,
              ),
              endLocation,
            ) <=
            arrivalThresholdMeters) {
          setState(() => rideEnded = true);
          _showRideEndDialog();
        }
      }
      return;
    }

    // Find nearest passenger
    double minDistance = double.infinity;
    String? nearestPassengerId;
    LatLng? nearestWaypoint;
    for (var passenger in unvisitedPassengers) {
      final waypointLatLng = passenger.waypoint;
      final distance = _calculateDistance(
        LatLng(
          currentPositionOfUser!.latitude,
          currentPositionOfUser!.longitude,
        ),
        waypointLatLng,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestPassengerId = passenger.passengerId;
        nearestWaypoint = waypointLatLng;
      }
    }

    setState(() {
      currentPassengerId = nearestPassengerId;
    });

    if (nearestPassengerId != null && nearestWaypoint != null) {
      // Check proximity to waypoint
      if (minDistance <= arrivalThresholdMeters && !showPickupDialog) {
        setState(() => showPickupDialog = true);
        _showPickupDialog(nearestPassengerId);
      } else {
        await getDirectionsWithWaypoints(
          LatLng(
            currentPositionOfUser!.latitude,
            currentPositionOfUser!.longitude,
          ),
          [],
          nearestWaypoint,
        );
        _addWaypointMarker(nearestWaypoint, nearestPassengerId);
      }
    }
  }

  Future<Map<String, dynamic>?> _fetchPassengerDetails(
    String passengerId,
  ) async {
    String? token = await _storage.read(key: 'jwt_token');
    if (token == null || token.isEmpty) {
      _showError('Authentication token not found');
      return null;
    }

    try {
      final response = await http.get(
        Uri.parse('http://172.20.10.2:9090/api/passenger/$passengerId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final details = jsonDecode(response.body);
        setState(() {
          passengerDetails[passengerId] = details;
        });
        return details;
      }
      _showError('Failed to fetch passenger details: ${response.statusCode}');
      return null;
    } catch (e) {
      _showError('Error fetching passenger details: $e');
      return null;
    }
  }

  Future<void> _initializeWebSocket() async {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
      _channel!.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) {
          _isWebSocketConnected = false;
          _attemptReconnection();
        },
        onDone: () {
          _isWebSocketConnected = false;
          _attemptReconnection();
        },
      );
      _sendInitialConnectionMessage();
      _startHeartbeat();
      setState(() => _isWebSocketConnected = true);
    } catch (e) {
      _isWebSocketConnected = false;
      _attemptReconnection();
    }
  }

  void _sendInitialConnectionMessage() {
    if (_channel != null && _isWebSocketConnected) {
      final message = {
        'type': 'driver_connected',
        'driver_id': rideData?.driverId ?? 'unknown',
        'ride_id': widget.rideId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_channel != null && _isWebSocketConnected) {
        final heartbeat = {
          'type': 'heartbeat',
          'driver_id': rideData?.driverId ?? 'unknown',
          'timestamp': DateTime.now().toIso8601String(),
        };
        try {
          _channel!.sink.add(jsonEncode(heartbeat));
        } catch (e) {
          _isWebSocketConnected = false;
          _attemptReconnection();
        }
      }
    });
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'location_received':
          break;
        case 'ride_update':
          setState(() {
            rideData = Ride.fromJson(
              data['ride_data']['rides'][0],
              rideData?.seatingCapacity ?? 4,
            );
            unvisitedPassengers = List.from(rideData!.passengers);
            // Re-fetch passenger details and addresses if needed
            for (var passenger in unvisitedPassengers) {
              if (passengerDetails[passenger.passengerId] == null) {
                _fetchPassengerDetails(passenger.passengerId);
              }
              if (waypointAddresses[passenger.passengerId] == null) {
                _fetchWaypointAddress(
                  passenger.passengerId,
                  passenger.waypoint,
                );
              }
            }
          });
          _updateNearestPassenger();
          break;
        default:
          debugPrint('Unknown message type: ${data['type']}');
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _sendLocationUpdate(LatLng location, {double? speed, double? heading}) {
    if (_channel != null && _isWebSocketConnected) {
      final locationData = {
        'type': 'location_update',
        'driver_id': rideData?.driverId ?? 'unknown',
        'ride_id': widget.rideId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'speed': speed ?? 0.0,
        'heading': heading ?? markerRotation.toDouble(),
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': currentPositionOfUser?.accuracy ?? 0.0,
      };
      try {
        _channel!.sink.add(jsonEncode(locationData));
      } catch (e) {
        _isWebSocketConnected = false;
        _attemptReconnection();
      }
    }
  }

  void _attemptReconnection() {
    if (_isWebSocketConnected) return;
    Timer(const Duration(seconds: 5), () {
      if (!_isWebSocketConnected) _initializeWebSocket();
    });
  }

  void _closeWebSocket() {
    try {
      if (_channel != null) {
        final disconnectMessage = {
          'type': 'driver_disconnected',
          'driver_id': rideData?.driverId ?? 'unknown',
          'ride_id': widget.rideId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _channel!.sink.add(jsonEncode(disconnectMessage));
        _channel!.sink.close(status.goingAway);
        _channel = null;
      }
      _isWebSocketConnected = false;
      _heartbeatTimer?.cancel();
    } catch (e) {
      debugPrint('Error closing WebSocket: $e');
    }
  }

  Future<void> _createCarMarkerIcon() async {
    try {
      final Uint8List markerIcon = await _getBytesFromAsset(
        'assets/car_icon.png',
        80,
      );
      setState(() {
        carIcon = BitmapDescriptor.fromBytes(markerIcon);
      });
    } catch (e) {
      debugPrint('Error creating car icon: $e');
      carIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueAzure,
      );
    }
  }

  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
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
    startLocationUpdates();
  }

  void startLocationUpdates() {
    locationUpdateTimer?.cancel();
    locationUpdateTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _updateDriverLocation();
    });
  }

  Future<void> _updateDriverLocation() async {
    try {
      Position currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      LatLng newLocation = LatLng(
        currentPosition.latitude,
        currentPosition.longitude,
      );
      setState(() {
        currentPositionOfUser = currentPosition;
      });

      if (previousPosition != null) {
        markerRotation = _calculateRotation(previousPosition!, newLocation);
      }

      _updateVehicleMarker(newLocation);
      _sendLocationUpdate(
        newLocation,
        speed: currentPosition.speed,
        heading: markerRotation.toDouble(),
      );
      previousPosition = newLocation;
      await _updateNearestPassenger();
    } catch (e) {
      debugPrint('Error updating location: $e');
      _showError('Error updating location: $e');
    }
  }

  void _updateVehicleMarker(LatLng newLocation) {
    if (carIcon != null) {
      setState(() {
        vehicleMarker = Marker(
          markerId: const MarkerId('vehicle'),
          position: newLocation,
          icon: carIcon!,
          rotation: markerRotation.toDouble(),
          anchor: const Offset(0.5, 0.5),
          flat: true,
          zIndex: 2,
        );
        markersSet.removeWhere((marker) => marker.markerId.value == 'vehicle');
        markersSet.add(vehicleMarker!);
      });
      _followVehicle(newLocation);
    }
  }

  int _calculateRotation(LatLng previous, LatLng current) {
    double deltaLng = current.longitude - previous.longitude;
    double deltaLat = current.latitude - previous.latitude;
    double rotation = atan2(deltaLng, deltaLat) * 180 / pi;
    return rotation.round();
  }

  void _followVehicle(LatLng position) {
    if (controllerGoogleMap != null) {
      controllerGoogleMap!.animateCamera(CameraUpdate.newLatLng(position));
    }
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

  Future<void> getDirectionsWithWaypoints(
    LatLng origin,
    List<LatLng> waypoints,
    LatLng destination,
  ) async {
    try {
      String waypointsString =
          waypoints.isNotEmpty
              ? "&waypoints=${waypoints.map((w) => "${w.latitude},${w.longitude}").join("|")}"
              : "";
      String url =
          "https://maps.googleapis.com/maps/api/directions/json?"
          "origin=${origin.latitude},${origin.longitude}"
          "&destination=${destination.latitude},${destination.longitude}"
          "$waypointsString"
          "&key=$googleAPIKey"
          "&mode=driving";

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        if (decodedData["status"] == "OK") {
          _decodePoints(decodedData);
        } else {
          debugPrint("Directions API error: ${decodedData["status"]}");
          drawSimplePolyline(origin, destination, waypoints);
        }
      } else {
        debugPrint("Failed to get directions: ${response.statusCode}");
        drawSimplePolyline(origin, destination, waypoints);
      }
    } catch (e) {
      debugPrint("Error getting directions: $e");
      drawSimplePolyline(origin, destination, waypoints);
    }
  }

  void _decodePoints(Map<String, dynamic> directionDetails) {
    polylineCoordinates.clear();
    if (directionDetails["routes"].isEmpty) return;

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
    polylineSet.clear();
    Polyline polyline = Polyline(
      polylineId: const PolylineId("route"),
      color: Colors.blue,
      points: polylineCoordinates,
      width: 5,
      jointType: JointType.round,
    );
    setState(() => polylineSet.add(polyline));
  }

  void drawSimplePolyline(
    LatLng origin,
    LatLng destination,
    List<LatLng> waypoints,
  ) {
    polylineCoordinates.clear();
    polylineSet.clear();
    polylineCoordinates.add(origin);
    polylineCoordinates.addAll(waypoints);
    polylineCoordinates.add(destination);
    _createPolyline();
  }

  void _addWaypointMarker(LatLng position, String passengerId) {
    final passenger = unvisitedPassengers.firstWhere(
      (p) => p.passengerId == passengerId,
    );
    Marker waypointMarker = Marker(
      markerId: MarkerId("waypoint_$passengerId"),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(
        passengerId == currentPassengerId
            ? BitmapDescriptor.hueGreen
            : BitmapDescriptor.hueOrange,
      ),
      infoWindow: InfoWindow(
        title: rideData!.waytowork ? "Pickup" : "Dropoff",
        snippet:
            "Passenger: ${passengerDetails[passengerId]?['name'] ?? 'Unknown'}",
      ),
    );
    setState(() {
      markersSet.removeWhere((m) => m.markerId.value.startsWith('waypoint_'));
      markersSet.add(waypointMarker);
    });
  }

  void _addDestinationMarker(LatLng position) {
    Marker dropOffMarker = Marker(
      markerId: const MarkerId("dropoff"),
      position: position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      infoWindow: InfoWindow(
        title: "Destination",
        snippet: rideData!.dropoffLocation,
      ),
    );
    setState(() {
      markersSet.removeWhere((m) => m.markerId.value == 'dropoff');
      markersSet.add(dropOffMarker);
    });
  }

  void _showPickupDialog(String passengerId) async {
    final passenger = unvisitedPassengers.firstWhere(
      (p) => p.passengerId == passengerId,
    );
    final details =
        passengerDetails[passengerId] ??
        await _fetchPassengerDetails(passengerId);
    final address =
        waypointAddresses[passengerId] ??
        await _reverseGeocode(passenger.waypoint);

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
                    Text(
                      rideData!.waytowork
                          ? 'Arrived at Pickup Location'
                          : 'Arrived at Dropoff Location',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
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
                  backgroundImage: NetworkImage(
                    details?['imageUrl'] ?? 'https://via.placeholder.com/150',
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  details?['name'] ?? 'Passenger',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Location: $address',
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
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
                          if (details?['phone'] != null) {
                            _makePhoneCall(details['phone']);
                          } else {
                            _showError('Passenger phone number not available');
                          }
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
                  onPressed: () async {
                    Navigator.of(context).pop();
                    setState(() {
                      showPickupDialog = false;
                      unvisitedPassengers.removeWhere(
                        (p) => p.passengerId == passengerId,
                      );
                    });
                    await _updateNearestPassenger();
                  },
                  child: Text(
                    rideData!.waytowork ? 'Confirm Pickup' : 'Confirm Dropoff',
                    style: const TextStyle(
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

  void _showRideEndDialog() {
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
                const Text(
                  'Ride Completed',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/main');
                  },
                  child: const Text(
                    'End Ride',
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

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showError('Could not launch phone call');
    }
  }

  Future<void> getCurrentLiveLocationOfUser() async {
    try {
      Position positionOfUser = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        currentPositionOfUser = positionOfUser;
      });
      LatLng positionOfUserInLatLng = LatLng(
        currentPositionOfUser!.latitude,
        currentPositionOfUser!.longitude,
      );

      previousPosition = positionOfUserInLatLng;
      _updateVehicleMarker(positionOfUserInLatLng);

      CameraPosition cameraPosition = CameraPosition(
        target: positionOfUserInLatLng,
        zoom: 15,
      );
      await controllerGoogleMap?.animateCamera(
        CameraUpdate.newCameraPosition(cameraPosition),
      );
    } catch (e) {
      _showError('Error getting location: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
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
                onPressed:
                    () => Navigator.of(context).pushReplacementNamed('/main'),
              ),
            ),
          ),
          if (!isLoading && rideData != null)
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Arriving in ${rideData!.duration}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            rideData!.startTime,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          LocationRow(
                            icon: Icons.my_location,
                            location: rideData!.pickupLocation,
                            color: Colors.black,
                          ),
                          const SizedBox(height: 12),
                          LocationRow(
                            icon: Icons.location_on,
                            location:
                                currentPassengerId != null
                                    ? waypointAddresses[currentPassengerId] ??
                                        'Loading...'
                                    : rideData!.dropoffLocation,
                            color: Colors.deepOrange,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Passengers',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...unvisitedPassengers.map((passenger) {
                            final passengerId = passenger.passengerId;
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            passengerDetails[passengerId]?['name'] ??
                                                'Loading...',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            rideData!.waytowork
                                                ? 'Pickup: ${waypointAddresses[passengerId] ?? 'Loading...'}'
                                                : 'Dropoff: ${waypointAddresses[passengerId] ?? 'Loading...'}',
                                          ),
                                          if (passengerId == currentPassengerId)
                                            const Text(
                                              'Next Waypoint',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (passengerDetails[passengerId]?['phone'] !=
                                        null)
                                      IconButton(
                                        icon: const Icon(
                                          Icons.phone,
                                          color: Colors.blue,
                                        ),
                                        onPressed:
                                            () => _makePhoneCall(
                                              passengerDetails[passengerId]['phone'],
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
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
