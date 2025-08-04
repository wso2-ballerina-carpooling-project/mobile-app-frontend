import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_frontend/services/call_service.dart';
import 'package:mobile_frontend/views/common/call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';

class DriverRideTracking extends StatefulWidget {
  final Ride ride;
  const DriverRideTracking({super.key, required this.ride});

  @override
  State<DriverRideTracking> createState() => _DriverRideTrackingState();
}

class _DriverRideTrackingState extends State<DriverRideTracking> {
  final String currentUserId = '';
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  Position? currentPosition;
  bool isLoading = true;
  Timer? locationUpdateTimer;
  List<Passenger> pickedUpPassengers = [];
  Passenger? nextPassenger;
  String? distanceText;
  String? durationText;
  String? etaText;
  String? passengerName;
  String fcm = "";
  String? phone;
  WebSocketChannel? _channel;
  bool _isWebSocketConnected = false;
  Timer? _heartbeatTimer;
  Map<String, dynamic> passengerDetails = {};
  Map<String, String> waypointAddresses = {};
  BitmapDescriptor? _pinIcon;
  BitmapDescriptor? _carIcon;
  LatLng? _previousDriverLocation;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _startRide();
  }

  Future<void> _startRide() async {
    const String baseUrl =
        'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';
    final url = Uri.parse('$baseUrl/rides/begin');

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'rideId': widget.ride.rideId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        await _checkLocationPermission();
        await _loadIcons();
        await _initializeWebSocket();
      } else {
        _showError('Failed to start ride: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error starting ride: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _endRide() async {
    const String baseUrl =
        'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';
    final url = Uri.parse('$baseUrl/rides/end');

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'rideId': widget.ride.rideId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        if (!_isDisposed) {
          Navigator.pop(context);
        }
      } else {
        _showError('Failed to end ride: ${response.statusCode}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      _showError('Error ending ride: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    locationUpdateTimer?.cancel();
    _closeWebSocket();
    mapController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!_isDisposed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
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

  Future<void> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showError('Location permissions are denied');
        setState(() {
          isLoading = false;
        });
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showError('Location permissions are permanently denied');
      setState(() {
        isLoading = false;
      });
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
        _updateMarkersAndRoute(LatLng(position.latitude, position.longitude));
        isLoading = false;
      });
    } catch (e) {
      _showError('Error getting location: $e');
      setState(() {
        isLoading = false;
      });
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
        _updateMarkersAndRoute(newPosition);
      });
      _sendLocationUpdate(
        newPosition,
        speed: position.speed,
        heading: position.heading,
      );
      _animateCameraToPosition(newPosition);
    } catch (e) {
      _showError('Error updating location: $e');
    }
  }

  void _updateMarkersAndRoute(LatLng driverPosition) {
    _addDriverMarker(driverPosition);
    if (pickedUpPassengers.length < widget.ride.passengers.length) {
      nextPassenger = _getNearestPassenger(driverPosition);
      if (nextPassenger != null) {
        _fetchDrivingRoute(driverPosition, nextPassenger!.waypoint);
      }
    } else {
      _fetchDrivingRoute(driverPosition, widget.ride.route.polyline.last);
    }
  }

  Passenger? _getNearestPassenger(LatLng driverPosition) {
    List<Passenger> remainingPassengers =
        widget.ride.passengers
            .where((p) => !pickedUpPassengers.contains(p))
            .toList();
    if (remainingPassengers.isEmpty) return null;

    Passenger nearestPassenger = remainingPassengers[0];
    double minDistance = _calculateDistance(
      driverPosition,
      nearestPassenger.waypoint,
    );

    for (var passenger in remainingPassengers.skip(1)) {
      double distance = _calculateDistance(driverPosition, passenger.waypoint);
      if (distance < minDistance) {
        minDistance = distance;
        nearestPassenger = passenger;
      }
    }
    return nearestPassenger;
  }

  Future<Map<String, dynamic>> _fetchPassengerDetails(
    String passengerId,
  ) async {
    const String baseUrl =
        'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';
    final url = Uri.parse('$baseUrl/passenger/$passengerId');

    try {
      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        final userDetails =
            decodedResponse['User'] as Map<String, dynamic>? ?? {};
        setState(() {
          passengerDetails[passengerId] = userDetails;
          if (nextPassenger?.passengerId == passengerId) {
            passengerName = userDetails['firstName'] as String? ?? 'Unknown';
            fcm = userDetails['fcm'] as String;
            print('passenegerId');
            print(fcm);
            phone = userDetails['phone'] as String;
          }
        });
        return userDetails;
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

  Future<void> _fetchWaypointAddress(
    String passengerId,
    LatLng waypoint,
  ) async {
    try {
      String url =
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=${waypoint.latitude},${waypoint.longitude}&key=AIzaSyBJToHkeu0EhfzRM64HXhCg2lil_Kg9pSE';
      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        if (decodedData['status'] == 'OK') {
          setState(() {
            waypointAddresses[passengerId] =
                decodedData['results'][0]['formatted_address'] as String;
          });
        } else {
          _showError(
            'Failed to fetch waypoint address: ${decodedData['status']}',
          );
        }
      } else {
        _showError('Failed to get waypoint address: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error fetching waypoint address: $e');
    }
  }

  Future<void> _fetchDrivingRoute(LatLng origin, LatLng destination) async {
    try {
      if (pickedUpPassengers.length < widget.ride.passengers.length &&
          nextPassenger != null) {
        if (passengerDetails[nextPassenger!.passengerId] == null) {
          await _fetchPassengerDetails(nextPassenger!.passengerId);
        }
        if (waypointAddresses[nextPassenger!.passengerId] == null) {
          await _fetchWaypointAddress(
            nextPassenger!.passengerId,
            nextPassenger!.waypoint,
          );
        }
      } else {
        setState(() {
          passengerName = null;
        });
      }

      int startIndex = _findClosestPolylineIndex(origin);
      int endIndex = _findClosestPolylineIndex(destination);

      if (startIndex > endIndex) {
        int temp = startIndex;
        startIndex = endIndex;
        endIndex = temp;
      }

      polylineCoordinates.clear();
      polylineCoordinates.addAll(
        widget.ride.route.polyline.sublist(startIndex, endIndex + 1),
      );
      _createPolyline();

      String url =
          'https://maps.googleapis.com/maps/api/distancematrix/json?origins=${origin.latitude},${origin.longitude}&destinations=${destination.latitude},${destination.longitude}&mode=driving&departure_time=now&traffic_model=best_guess&units=metric&key=AIzaSyBJToHkeu0EhfzRM64HXhCg2lil_Kg9pSE';

      var response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        var decodedData = jsonDecode(response.body);
        if (decodedData['status'] == 'OK') {
          var element = decodedData['rows'][0]['elements'][0];
          if (element['status'] == 'OK') {
            setState(() {
              distanceText = element['distance']['text'];
              durationText = element['duration_in_traffic']['text'];
              int durationSeconds = element['duration_in_traffic']['value'];
              DateTime eta = DateTime.now().add(
                Duration(seconds: durationSeconds),
              );
              etaText = '${eta.hour}:${eta.minute.toString().padLeft(2, '0')}';
            });
          } else {
            _showError('Distance Matrix API error: ${element['status']}');
          }
        } else {
          _showError('Failed to fetch distance data: ${decodedData['status']}');
        }
      } else {
        _showError('Failed to get distance data: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error generating route or fetching distance: $e');
    }
  }

  int _findClosestPolylineIndex(LatLng position) {
    int closestIndex = 0;
    double minDistance = _calculateDistance(
      position,
      widget.ride.route.polyline[0],
    );

    for (int i = 1; i < widget.ride.route.polyline.length; i++) {
      double distance = _calculateDistance(
        position,
        widget.ride.route.polyline[i],
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  void _createPolyline() {
    polylines.clear();
    if (polylineCoordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
          jointType: JointType.round,
        ),
      );
      setState(() {});
    }
  }

  double _calculateRotation(LatLng start, LatLng end) {
    double latDiff = end.latitude - start.latitude;
    double lngDiff = end.longitude - start.longitude;
    double angle = atan2(lngDiff, latDiff);
    return angle * 180 / pi;
  }

  void _addDriverMarker(LatLng position) {
    markers.clear();
    double rotation = 0;

    if (_previousDriverLocation != null) {
      rotation = _calculateRotation(_previousDriverLocation!, position);
    }
    markers.add(
      Marker(
        markerId: const MarkerId('driver'),
        position: position,
        icon: _carIcon!,
        anchor: const Offset(0.5, 0.5),
        rotation: rotation,
      ),
    );
    _previousDriverLocation = position;

    markers.add(
      Marker(
        markerId: const MarkerId('end'),
        position: widget.ride.route.polyline.last,
        icon: _pinIcon!,
        infoWindow: InfoWindow(title: widget.ride.dropoffLocation),
      ),
    );
    for (var passenger in widget.ride.passengers) {
      if (!pickedUpPassengers.contains(passenger)) {
        markers.add(
          Marker(
            markerId: MarkerId('passenger_${passenger.passengerId}'),
            position: passenger.waypoint,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueBlue,
            ),
            infoWindow: InfoWindow(title: passengerName ?? passenger.address),
          ),
        );
      }
    }
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

  void _confirmPassengerPickup(Passenger passenger) {
    if (_channel != null && _isWebSocketConnected) {
      final pickupMessage = {
        'type': 'passenger_picked_up',
        'driver_id': widget.ride.driverId,
        'ride_id': widget.ride.rideId,
        'passenger_id': passenger.passengerId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      try {
        _channel!.sink.add(jsonEncode(pickupMessage));
        print(
          "📤 Sent passenger picked up message: ${jsonEncode(pickupMessage)}",
        );
      } catch (e) {
        _showError('Error sending pickup confirmation: $e');
        _isWebSocketConnected = false;
        _attemptReconnection();
        return;
      }
    }

    setState(() {
      pickedUpPassengers.add(passenger);
      nextPassenger = _getNearestPassenger(
        LatLng(currentPosition!.latitude, currentPosition!.longitude),
      );
      distanceText = null;
      durationText = null;
      etaText = null;
      passengerName = null;
    });
    _updateMarkersAndRoute(
      LatLng(currentPosition!.latitude, currentPosition!.longitude),
    );
  }

  Future<void> _initializeWebSocket() async {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse(
          "wss://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/websocket/websocket/v1.0",
        ),
      );

      _channel!.stream.listen(
        (message) => _handleWebSocketMessage(message),
        onError: (error) {
          _isWebSocketConnected = false;
          if (!_isDisposed) _attemptReconnection();
        },
        onDone: () {
          _isWebSocketConnected = false;
          if (!_isDisposed) _attemptReconnection();
        },
      );

      _isWebSocketConnected = true;
      _startHeartbeat();

      await Future.delayed(Duration(milliseconds: 300));
      _sendInitialConnectionMessage();

      setState(() {});
    } catch (e) {
      _isWebSocketConnected = false;
      _attemptReconnection();
    }
  }

  void _sendInitialConnectionMessage() async {
    if (_channel != null && _isWebSocketConnected) {
      final message = {
        'type': 'driver_connected',
        'driver_id': widget.ride.driverId,
        'ride_id': widget.ride.rideId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      print("📤 Sending initial connection message: ${jsonEncode(message)}");
      _channel!.sink.add(jsonEncode(message));
    } else {
      print(
        "⚠️ WebSocket not connected, cannot send initial connection message",
      );
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_channel != null && _isWebSocketConnected) {
        final heartbeat = {
          'type': 'heartbeat',
          'driver_id': widget.ride.driverId,
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
        case 'passenger_picked_up_ack':
          print("✅ Received pickup acknowledgment: ${jsonEncode(data)}");
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  Future<void> _loadIcons() async {
    const imageConfiguration = ImageConfiguration(size: Size(48, 48));
    _pinIcon = await BitmapDescriptor.asset(
      imageConfiguration,
      'assets/pin.png',
    );
    _carIcon = await BitmapDescriptor.asset(
      imageConfiguration,
      'assets/car-d.png',
    );
  }

  void _sendLocationUpdate(LatLng location, {double? speed, double? heading}) {
    if (_channel != null && _isWebSocketConnected) {
      final locationData = {
        'type': 'location_update',
        'driver_id': widget.ride.driverId,
        'ride_id': widget.ride.rideId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'speed': speed ?? 0.0,
        'heading': heading ?? 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'accuracy': currentPosition?.accuracy ?? 0.0,
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
    if (_isWebSocketConnected || _isDisposed) return;
    Timer(const Duration(seconds: 5), () {
      if (!_isWebSocketConnected && !_isDisposed) _initializeWebSocket();
    });
  }

  void _closeWebSocket() {
    try {
      if (_channel != null) {
        final disconnectMessage = {
          'type': 'driver_disconnected',
          'driver_id': widget.ride.driverId,
          'ride_id': widget.ride.rideId,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _channel!.sink.add(jsonEncode(disconnectMessage));
        _channel!.sink.close();
        _channel = null;
      }
      _isWebSocketConnected = false;
      _heartbeatTimer?.cancel();
    } catch (e) {
      debugPrint('Error closing WebSocket: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 8.0),
          decoration: const BoxDecoration(
            color: mainButtonColor,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                onMapCreated: (controller) {
                  mapController = controller;
                  updateMapTheme(controller);
                },
                initialCameraPosition: CameraPosition(
                  target:
                      currentPosition != null
                          ? LatLng(
                            currentPosition!.latitude,
                            currentPosition!.longitude,
                          )
                          : widget.ride.route.polyline.first,
                  zoom: 14.0,
                ),
                markers: markers,
                polylines: polylines,
                myLocationEnabled: true,
              ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[900]!, Colors.black87],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Colors.blue[400],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    nextPassenger != null
                                        ? 'To: ${waypointAddresses[nextPassenger!.passengerId] ?? nextPassenger!.address}'
                                        : 'To: ${widget.ride.dropoffLocation}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            if (passengerName != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.person,
                                    color: Colors.green[400],
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Passenger: $passengerName',
                                      style: TextStyle(
                                        color: Colors.grey[300],
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey[700]!,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    Icons.straighten,
                                    'Distance',
                                    distanceText ?? "Calculating...",
                                    Colors.orange[400]!,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.schedule,
                                    'Duration',
                                    durationText ?? "Calculating...",
                                    Colors.purple[400]!,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildInfoRow(
                                    Icons.access_time,
                                    'ETA',
                                    etaText ?? "Calculating...",
                                    Colors.blue[400]!,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (nextPassenger != null) ...[
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.green[600],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.call, color: Colors.white),
                            onPressed: () async {
                              _closeWebSocket();
                              try {
                                final callId =
                                    "1234"; // Use current user ID
                                final channelName =
                                    'ride_${widget.ride.rideId}'; // Unique channel per ride
                                final response =
                                    await CallService.getAgoraToken(
                                      channelName,
                                      callId,
                                    );
                                final prefs = await SharedPreferences.getInstance();
                                final driverName = prefs.getString('firstName') ?? 'Driver';

                                await CallService.sendCallNotification(
                                  driverId: "1234",
                                  callId: callId,
                                  channelName: channelName,
                                  callerName: driverName,
                                  passengerId: fcm
                                );

                                // Send FCM notification to the driver

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => CallingScreen(
                                          uid: 1234,
                                          token: response,
                                          channelName: channelName,
                                          contactName: passengerName,
                                          // Display recipient's name
                                        ),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error initiating call: $e'),
                                  ),
                                );
                              }
                            },
                            tooltip: 'Call Passenger',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8), // Space between box and button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child:
                      nextPassenger != null
                          ? ElevatedButton(
                            onPressed:
                                () => _confirmPassengerPickup(nextPassenger!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Confirm Pickup: ${passengerName ?? "Passenger"}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ElevatedButton(
                            onPressed: _endRide,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'End Trip',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
