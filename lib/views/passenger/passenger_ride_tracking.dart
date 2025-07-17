import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/models/RideData.dart';

class PassengerRideTracking extends StatefulWidget {
  final Ride ride;
  final String passengerId;
  const PassengerRideTracking({super.key, required this.ride, required this.passengerId});

  @override
  State<PassengerRideTracking> createState() => _PassengerRideTrackingState();
}

class _PassengerRideTrackingState extends State<PassengerRideTracking> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  List<LatLng> polylineCoordinates = [];
  bool isLoading = true;
  String? distanceText;
  String? durationText;
  String? etaText;
  String? driverName;
  WebSocketChannel? _channel;
  bool _isWebSocketConnected = false;
  Timer? _heartbeatTimer;
  BitmapDescriptor? _pinIcon;
  BitmapDescriptor? _carIcon;
  LatLng? _driverPosition;
  LatLng? _currentPassengerWaypoint;
  bool _isPassengerPickedUp = false;

  // Current date and time: 06:27 PM +0530, Thursday, July 17, 2025
  final DateTime _currentTime = DateTime(2025, 7, 17, 18, 27);

  @override
  void initState() {
    super.initState();
    _loadIcons();
    _initializeWebSocket();
    _findCurrentPassenger();
  }

  @override
  void dispose() {
    _closeWebSocket();
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

  void _findCurrentPassenger() async {
    final prefs = await SharedPreferences.getInstance();
    final loggedInPassengerId = prefs.getString('id');
    if (loggedInPassengerId != null) {
      final currentPassenger = widget.ride.passengers.firstWhere(
        (passenger) => passenger.passengerId == loggedInPassengerId,
        orElse: () => throw Exception('Current passenger not found'),
      );
      setState(() {
        _currentPassengerWaypoint = currentPassenger.waypoint;
      });
    } else {
      _showError('Passenger ID not found');
    }
  }

  void _updateMarkers(LatLng passengerPosition) {
    markers.clear();
    if (_driverPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position: _driverPosition!,
          icon: _carIcon!,
          anchor: const Offset(0.5, 0.5),
        ),
      );
    }
    markers.add(
      Marker(
        markerId: const MarkerId('passenger'),
        position: passengerPosition,
        icon: _pinIcon!,
        infoWindow: InfoWindow(title: 'Your Location'),
      ),
    );
    setState(() {});
  }

  Future<void> _fetchDrivingRoute(LatLng origin, LatLng destination) async {
    try {
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
              DateTime eta = _currentTime.add(Duration(seconds: durationSeconds));
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

  Future<void> _loadIcons() async {
    const imageConfiguration = ImageConfiguration(size: Size(48, 48));
    _pinIcon = await BitmapDescriptor.asset(imageConfiguration, 'assets/pin.png');
    _carIcon = await BitmapDescriptor.asset(imageConfiguration, 'assets/car-d.png');
    setState(() {
      isLoading = false;
    });
  }

  void _animateCameraToPosition(LatLng position) {
    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15.0),
      duration: const Duration(milliseconds: 500),
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
          _attemptReconnection();
        },
        onDone: () {
          _isWebSocketConnected = false;
          _attemptReconnection();
        },
      );

      _isWebSocketConnected = true;
      await Future.delayed(Duration(milliseconds: 300));
      _sendInitialConnectionMessage();

      setState(() {});
    } catch (e) {
      _isWebSocketConnected = false;
      _attemptReconnection();
    }
  }

  void _sendInitialConnectionMessage() async {
    if (_channel != null && _isWebSocketConnected && _currentPassengerWaypoint != null) {
      final message = {
        'type': 'passenger_connected',
        'passenger_id': widget.passengerId,
        'driver_id': widget.ride.driverId,
      };
      print("📤 Sending initial connection message: ${jsonEncode(message)}");
      _channel!.sink.add(jsonEncode(message));
    } else {
      print("⚠️ WebSocket not connected or passenger waypoint not found");
    }
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      switch (data['type']) {
        case 'driver_location_update':
          setState(() {
            _driverPosition = LatLng(data['latitude'], data['longitude']);
            if (_driverPosition != null && _currentPassengerWaypoint != null && !_isPassengerPickedUp) {
              _updateMarkers(_currentPassengerWaypoint!);
              _fetchDrivingRoute(_driverPosition!, _currentPassengerWaypoint!);
              _animateCameraToPosition(_driverPosition!);
              _updatePolyline();
            }
          });
          break;
        case 'pickup_confirmation':
          if (data['driver_location'] != null) {
            setState(() {
              _driverPosition = LatLng(data['driver_location']['latitude'], data['driver_location']['longitude']);
              driverName = data['driver_name'] ?? 'Unknown Driver';
              if (_driverPosition != null && _currentPassengerWaypoint != null && !_isPassengerPickedUp) {
                _updateMarkers(_currentPassengerWaypoint!);
                _fetchDrivingRoute(_driverPosition!, _currentPassengerWaypoint!);
                _animateCameraToPosition(_driverPosition!);
                _updatePolyline();
              }
            });
          }
          break;
        case 'passenger_picked_up':
          setState(() {
            _isPassengerPickedUp = true;
            _updateMarkers(widget.ride.route.polyline.last);
            if (_driverPosition != null) {
              _fetchDrivingRoute(_driverPosition!, widget.ride.route.polyline.last);
              _animateCameraToPosition(_driverPosition!);
              _updatePolyline();
            }
          });
          break;
      }
    } catch (e) {
      debugPrint('Error handling WebSocket message: $e');
    }
  }

  void _updatePolyline() {
    polylines.clear();
    polylineCoordinates.clear();

    if (_driverPosition != null) {
      polylineCoordinates.add(_driverPosition!);

      if (!_isPassengerPickedUp && _currentPassengerWaypoint != null) {
        // Before pickup, use the route up to the current passenger's waypoint
        final passengerIndex = widget.ride.route.polyline.indexWhere(
          (point) => point.latitude == _currentPassengerWaypoint!.latitude &&
              point.longitude == _currentPassengerWaypoint!.longitude,
        );
        if (passengerIndex != -1) {
          polylineCoordinates.addAll(widget.ride.route.polyline.sublist(0, passengerIndex + 1));
        } else {
          polylineCoordinates.addAll(widget.ride.route.polyline); // Fall back to full route if waypoint not found
        }
      } else {
        // After pickup, use the full route
        polylineCoordinates.addAll(widget.ride.route.polyline);
      }

      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          color: Colors.blue,
          points: polylineCoordinates,
          width: 5,
          jointType: JointType.round,
        ),
      );
    }
    setState(() {});
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
          'type': 'passenger_disconnected',
          'passenger_id': widget.passengerId,
          'driver_id': widget.ride.driverId,
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
                    target: _currentPassengerWaypoint ?? widget.ride.route.polyline.first,
                    zoom: 15,
                  ),
                  markers: markers,
                  polylines: polylines,
                  myLocationEnabled: false,
                ),
          Positioned(
            bottom: 20,
            left: 16,
            right: 16,
            child: Container(
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
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.blue[400], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          driverName != null ? 'Driver: $driverName' : 'Driver: Assigning...',
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
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[700]!, width: 0.5),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.straighten, 'Distance', distanceText ?? "Calculating...", Colors.orange[400]!),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.schedule, 'Duration', durationText ?? "Calculating...", Colors.purple[400]!),
                        const SizedBox(height: 8),
                        _buildInfoRow(Icons.access_time, 'ETA', etaText ?? "Calculating...", Colors.blue[400]!),
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

  Widget _buildInfoRow(IconData icon, String label, String value, Color iconColor) {
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