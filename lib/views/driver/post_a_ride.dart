import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/common/select_location.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';

class RidePostScreen extends StatefulWidget {
  const RidePostScreen({Key? key}) : super(key: key);

  @override
  State<RidePostScreen> createState() => _RidePostScreenState();
}

class _RidePostScreenState extends State<RidePostScreen> {
  String? selectedTime;
  String? selectedReturnTime;
  bool isVehicleRegEditable = false;
  final TextEditingController pickUpController = TextEditingController();
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController vehicleRegController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  bool _isPosting = false;
  bool isPickUpLocked = false;
  bool isDropOffLocked = false;
  bool isWSO2Start = false;

  // Google Maps Controller
  GoogleMapController? mapController;
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(6.7734, 79.8825), // WSO2 coordinates
    zoom: 14.0,
  );

  // Map variables
  Set<Marker> markers = {};
  Map<PolylineId, Polyline> polylines = {};
  List<List<LatLng>> routeOptions = [];
  int selectedRouteIndex = 0;
  bool isMapVisible = false;
  bool isLoading = false;

  // Route information
  List<String> routeDurations = [];
  List<String> routeDistances = [];

  String? pickUpPlaceId;
  String? dropOffPlaceId;

  // WSO2 specific variables
  final String wso2Address = "WSO2, Bauddhaloka Mawatha, Colombo, Sri Lanka";
  final LatLng wso2Coordinates = const LatLng(6.8953284, 79.8546711);

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    setState(() {
      pickUpController.text = "";
      dropOffController.text = "";
      isWSO2Start = true;
      isPickUpLocked = false;
      isDropOffLocked = false;
    });
  }

  Future<String?> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}, ${place.country}';
        return address;
      }
    } catch (e) {
      print('Error getting address: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting address: $e')));
    }
    return null;
  }

  Future<void> _selectLocation(bool isPickup) async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SelectLocation(
              initialLocation:
                  isPickup
                      ? _selectedLocationFromLatLng(pickUpController.text)
                      : _selectedLocationFromLatLng(dropOffController.text),
            ),
      ),
    );

    if (selectedLocation != null) {
      String? address = await _getAddressFromLatLng(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );
      setState(() {
        if (isPickup) {
          pickUpController.text =
              address ??
              "Selected Location (${selectedLocation.latitude}, ${selectedLocation.longitude})";
          pickUpPlaceId = null; // No place ID for map-selected location
          isWSO2Start = pickUpController.text.toLowerCase().contains('wso2');
          if (!isWSO2Start && dropOffController.text.isEmpty) {
            dropOffController.text = wso2Address;
            dropOffPlaceId = null;
            isDropOffLocked = true;
            isPickUpLocked = false;
          } else {
            isDropOffLocked = false;
            isPickUpLocked = false;
          }
        } else {
          dropOffController.text =
              address ??
              "Selected Location (${selectedLocation.latitude}, ${selectedLocation.longitude})";
          dropOffPlaceId = null; // No place ID for map-selected location
          if (!dropOffController.text.toLowerCase().contains('wso2') &&
              pickUpController.text.isEmpty) {
            pickUpController.text = wso2Address;
            pickUpPlaceId = null;
            isWSO2Start = true;
            isPickUpLocked = true;
            isDropOffLocked = false;
          } else {
            isPickUpLocked = false;
            isDropOffLocked = false;
          }
        }
      });
      await _showRoutes();
    }
  }

  LatLng? _selectedLocationFromLatLng(String address) {
    if (address.toLowerCase() == wso2Address.toLowerCase()) {
      return wso2Coordinates;
    }
    return null; // Default to initial map position if not WSO2
  }

  Future<void> _showRoutes() async {
    setState(() {
      isLoading = true;
      isMapVisible = true;
    });

    try {
      LatLng originLatLng =
          _selectedLocationFromLatLng(pickUpController.text) ?? wso2Coordinates;
      LatLng destLatLng =
          _selectedLocationFromLatLng(dropOffController.text) ??
          wso2Coordinates;

      if (pickUpController.text != wso2Address) {
        List<Location> locations = await locationFromAddress(
          "${pickUpController.text}, Sri Lanka",
        );
        if (locations.isNotEmpty) {
          originLatLng = LatLng(locations[0].latitude, locations[0].longitude);
        }
      }
      if (dropOffController.text != wso2Address) {
        List<Location> locations = await locationFromAddress(
          "${dropOffController.text}, Sri Lanka",
        );
        if (locations.isNotEmpty) {
          destLatLng = LatLng(locations[0].latitude, locations[0].longitude);
        }
      }

      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          originLatLng.latitude < destLatLng.latitude
              ? originLatLng.latitude
              : destLatLng.latitude,
          originLatLng.longitude < destLatLng.longitude
              ? originLatLng.longitude
              : destLatLng.longitude,
        ),
        northeast: LatLng(
          originLatLng.latitude > destLatLng.latitude
              ? originLatLng.latitude
              : destLatLng.latitude,
          originLatLng.longitude > destLatLng.longitude
              ? originLatLng.longitude
              : destLatLng.longitude,
        ),
      );

      await _getDirections(originLatLng, destLatLng);

      setState(() {
        markers = {
          Marker(
            markerId: const MarkerId('origin'),
            position: originLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
            infoWindow: InfoWindow(
              title: 'Pickup',
              snippet: pickUpController.text,
            ),
          ),
          Marker(
            markerId: const MarkerId('destination'),
            position: destLatLng,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Drop-off',
              snippet: dropOffController.text,
            ),
          ),
        };

        mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
      });
    } catch (e) {
      print('Error showing routes: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Error displaying routes')));
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    const apiKey = 'AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/directions/json?'
      'origin=${origin.latitude},${origin.longitude}'
      '&destination=${destination.latitude},${destination.longitude}'
      '&alternatives=true'
      '&mode=driving'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final routes = data['routes'] as List;

          setState(() {
            polylines.clear();
            routeOptions.clear();
            routeDurations.clear();
            routeDistances.clear();
          });

          for (int i = 0; i < routes.length; i++) {
            final route = routes[i];
            final legs = route['legs'][0];
            final String duration = legs['duration']['text'];
            final String distance = legs['distance']['text'];

            routeDurations.add(duration);
            routeDistances.add(distance);

            final points = route['overview_polyline']['points'];
            final polylinePoints = PolylinePoints().decodePolyline(points);
            List<LatLng> polylineCoordinates = [];

            for (var point in polylinePoints) {
              polylineCoordinates.add(LatLng(point.latitude, point.longitude));
            }

            routeOptions.add(polylineCoordinates);

            final PolylineId polylineId = PolylineId('route$i');
            final Polyline polyline = Polyline(
              polylineId: polylineId,
              color: i == selectedRouteIndex ? Colors.blue : Colors.grey,
              points: polylineCoordinates,
              width: i == selectedRouteIndex ? 6 : 3,
            );

            setState(() {
              polylines[polylineId] = polyline;
            });
          }

          if (selectedRouteIndex >= routeOptions.length) {
            selectedRouteIndex = 0;
          }
        } else {
          throw Exception('Failed to get directions: ${data['status']}');
        }
      } else {
        throw Exception('Failed to fetch directions');
      }
    } catch (e) {
      print('Error getting directions: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting directions: $e')));
    }
  }

  void _selectRoute(int index) {
    setState(() {
      selectedRouteIndex = index;

      for (int i = 0; i < routeOptions.length; i++) {
        final PolylineId polylineId = PolylineId('route$i');
        final Polyline currentPolyline = polylines[polylineId]!;

        polylines[polylineId] = Polyline(
          polylineId: currentPolyline.polylineId,
          color: i == selectedRouteIndex ? Colors.blue : Colors.grey,
          points: currentPolyline.points,
          width: i == selectedRouteIndex ? 6 : 3,
        );
      }
    });
  }

  List<String> _getTimeOptions() {
    if (isWSO2Start) {
      return ['17:00:00', '18:00:00', '19:00:00'];
    } else {
      return ['08:00:00', '09:00:00', '10:00:00'];
    }
  }

  Future<List<Map<String, dynamic>>> searchSriLankaPlaces(String query) async {
    if (query.length < 3) return [];

    const apiKey = 'AIzaSyBJToHkeu0EhfzRM64HXhCg2lil_Kg9pSE';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
      'input=$query'
      '&components=country:lk'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List;
          return predictions.map((prediction) {
            return {
              'description': prediction['description'],
              'place_id': prediction['place_id'],
            };
          }).toList();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Place search failed: ${data['status']}')),
          );
          return [];
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to fetch place suggestions')),
        );
        return [];
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching places: $e')));
      return [];
    }
  }

  Future<LatLng?> getPlaceDetails(String placeId) async {
    const apiKey = 'AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?'
      'place_id=$placeId'
      '&fields=geometry'
      '&key=$apiKey',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print('Error getting place details: $e');
      return null;
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

  Future<void> _postRide() async {
    // Validate all required fields
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Additional checks for required fields
    if (pickUpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a starting point')),
      );
      return;
    }
    if (dropOffController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a destination')),
      );
      return;
    }
    if (dateController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date')));
      return;
    }
    if (selectedTime == null || selectedTime!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a time')));
      return;
    }
    if (routeOptions.isEmpty || selectedRouteIndex >= routeOptions.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid route')),
      );
      return;
    }

    // Validate ride time (must be at least 12 hours in the future)
    try {
      final List<String> dateParts = dateController.text.split('/');
      if (dateParts.length != 3) {
        throw Exception('Invalid date format');
      }
      final int day = int.parse(dateParts[0]);
      final int month = int.parse(dateParts[1]);
      final int year = int.parse(dateParts[2]);
      final List<String> timeParts = (selectedTime ?? '').split(':');
      if (timeParts.length != 3) {
        throw Exception('Invalid time format');
      }
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final int second = int.parse(timeParts[2]);

      final DateTime rideDateTime = DateTime(
        year,
        month,
        day,
        hour,
        minute,
        second,
      );
      final DateTime now = DateTime.now();
      final DateTime earliestAllowedTime = now.add(const Duration(hours: 12));

      if (rideDateTime.isBefore(earliestAllowedTime)) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                elevation: 8,
                title: const Text(
                  'Invalid Ride Time',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: const Text(
                  'Rides must be scheduled at least 12 hours in advance.',
                  style: TextStyle(color: Colors.black87, fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: linkColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      side: BorderSide(color: linkColor, width: 1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
        );
        return;
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error parsing date or time: $e')));
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.6),
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            title: const Text(
              'Confirm Ride Post',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to post this ride?',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  side: BorderSide(color: linkColor, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text(
                  'Confirm',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      setState(() {
        _isPosting = true;
      });

      try {
        final token = await _storage.read(key: 'jwt_token');
        if (token == null) {
          throw Exception('No authentication token found');
        }
        bool waytowork = true;
        if (pickUpController.text == wso2Address) {
          waytowork = false;
        }
        final routeData =
            selectedRouteIndex < routeOptions.length
                ? {
                  'index': selectedRouteIndex,
                  'duration': routeDurations[selectedRouteIndex],
                  'distance': routeDistances[selectedRouteIndex],
                  'polyline':
                      routeOptions[selectedRouteIndex]
                          .map(
                            (point) => {
                              'latitude': point.latitude,
                              'longitude': point.longitude,
                            },
                          )
                          .toList(),
                }
                : null;

        final rideData = {
          'startLocation': pickUpController.text,
          'endLocation': dropOffController.text,
          'waytowork': waytowork,
          'date': dateController.text,
          'time': selectedTime ?? '',
          'route': routeData,
        };

        final response = await RideService.postRide(rideData, token);

        print(response.body);
        setState(() {
          _isPosting = false;
        });

        if (response.statusCode == 201) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Success',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  content: const Text(
                    'Ride posted successfully!',
                    style: TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: mainButtonColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close AlertDialog
                        Navigator.pop(context); // Navigate back
                      },
                      child: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
          );
        } else {
          final errorMessage =
              jsonDecode(response.body)['message'] ?? 'Failed to post ride';
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  backgroundColor: Colors.white,
                  title: const Text(
                    'Failure',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  content: Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.black87, fontSize: 16),
                  ),
                  actions: [
                    TextButton(
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        _postRide(); // Retry logic
                      },
                      child: const Text(
                        'Post Again',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ],
                ),
          );
        }
      } catch (e) {
        setState(() {
          _isPosting = false;
        });
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('Failure'),
                content: Text('Error posting ride: $e'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _postRide();
                    },
                    child: const Text('Post Again'),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  void dispose() {
    pickUpController.dispose();
    dropOffController.dispose();
    dateController.dispose();
    vehicleRegController.dispose();
    mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      body: Stack(
        children: [
          SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 12,
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ),
                          const Positioned(
                            left: 0,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Center(
                              child: Text(
                                'Post a Ride',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width * 0.5,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ride Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Center(
                                    child: Container(
                                      height: 2,
                                      width: 50,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            isPickUpLocked
                                                ? TextFormField(
                                                  controller: pickUpController,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText:
                                                            'Starting-Point',
                                                        hintText:
                                                            'Your Location',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 15,
                                                            ),
                                                        suffixIcon: Icon(
                                                          Icons.lock,
                                                        ),
                                                      ),
                                                  readOnly: true,
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter a starting point';
                                                    }
                                                    return null;
                                                  },
                                                )
                                                : TypeAheadField<
                                                  Map<String, dynamic>
                                                >(
                                                  textFieldConfiguration: TextFieldConfiguration(
                                                    controller:
                                                        pickUpController,
                                                    decoration: InputDecoration(
                                                      labelText:
                                                          'Starting-Point',
                                                      hintText:
                                                          'Search or tap map icon',
                                                      border:
                                                          const OutlineInputBorder(),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 15,
                                                          ),
                                                      suffixIcon: IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .location_on_sharp,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _selectLocation(
                                                                  true,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  suggestionsCallback: (
                                                    pattern,
                                                  ) async {
                                                    if (pattern.length >= 3) {
                                                      return await searchSriLankaPlaces(
                                                        pattern,
                                                      );
                                                    }
                                                    return [];
                                                  },
                                                  itemBuilder: (
                                                    context,
                                                    suggestion,
                                                  ) {
                                                    return ListTile(
                                                      leading: const Icon(
                                                        Icons.location_on,
                                                      ),
                                                      title: Text(
                                                        suggestion['description'],
                                                      ),
                                                      subtitle: const Text(
                                                        'Sri Lanka',
                                                      ),
                                                    );
                                                  },
                                                  onSuggestionSelected: (
                                                    suggestion,
                                                  ) {
                                                    setState(() {
                                                      pickUpController.text =
                                                          suggestion['description'];
                                                      pickUpPlaceId =
                                                          suggestion['place_id'];
                                                      isWSO2Start =
                                                          suggestion['description']
                                                              .toLowerCase()
                                                              .contains('wso2');
                                                      if (!isWSO2Start) {
                                                        dropOffController.text =
                                                            wso2Address;
                                                        dropOffPlaceId = null;
                                                      }
                                                    });
                                                  },
                                                  noItemsFoundBuilder:
                                                      (
                                                        context,
                                                      ) => const Padding(
                                                        padding: EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                        child: Text(
                                                          'No locations found',
                                                        ),
                                                      ),
                                                  suggestionsBoxDecoration:
                                                      SuggestionsBoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        elevation: 4,
                                                        color: Colors.white,
                                                        constraints:
                                                            const BoxConstraints(
                                                              maxHeight: 200,
                                                            ),
                                                      ),
                                                  debounceDuration:
                                                      const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child:
                                            isWSO2Start
                                                ? TypeAheadField<
                                                  Map<String, dynamic>
                                                >(
                                                  textFieldConfiguration: TextFieldConfiguration(
                                                    controller:
                                                        dropOffController,
                                                    decoration: InputDecoration(
                                                      labelText: 'End-Point',
                                                      hintText:
                                                          'Search or tap map icon',
                                                      border:
                                                          const OutlineInputBorder(),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 15,
                                                          ),
                                                      suffixIcon: IconButton(
                                                        icon: const Icon(
                                                          Icons
                                                              .location_on_sharp,
                                                        ),
                                                        onPressed:
                                                            () =>
                                                                _selectLocation(
                                                                  false,
                                                                ),
                                                      ),
                                                    ),
                                                  ),
                                                  suggestionsCallback: (
                                                    pattern,
                                                  ) async {
                                                    if (pattern.length >= 3) {
                                                      return await searchSriLankaPlaces(
                                                        pattern,
                                                      );
                                                    }
                                                    return [];
                                                  },
                                                  itemBuilder: (
                                                    context,
                                                    suggestion,
                                                  ) {
                                                    return ListTile(
                                                      leading: const Icon(
                                                        Icons.location_on,
                                                      ),
                                                      title: Text(
                                                        suggestion['description'],
                                                      ),
                                                      subtitle: const Text(
                                                        'Sri Lanka',
                                                      ),
                                                    );
                                                  },
                                                  onSuggestionSelected: (
                                                    suggestion,
                                                  ) {
                                                    setState(() {
                                                      dropOffController.text =
                                                          suggestion['description'];
                                                      dropOffPlaceId =
                                                          suggestion['place_id'];
                                                      if (!suggestion['description']
                                                              .toLowerCase()
                                                              .contains(
                                                                'wso2',
                                                              ) &&
                                                          pickUpController
                                                              .text
                                                              .isEmpty) {
                                                        pickUpController.text =
                                                            wso2Address;
                                                        pickUpPlaceId = null;
                                                        isWSO2Start = true;
                                                        isPickUpLocked = true;
                                                        isDropOffLocked = false;
                                                      } else {
                                                        isPickUpLocked = false;
                                                        isDropOffLocked = false;
                                                      }
                                                    });
                                                  },
                                                  noItemsFoundBuilder:
                                                      (
                                                        context,
                                                      ) => const Padding(
                                                        padding: EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                        child: Text(
                                                          'No locations found',
                                                        ),
                                                      ),
                                                  suggestionsBoxDecoration:
                                                      SuggestionsBoxDecoration(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                        elevation: 4,
                                                        color: Colors.white,
                                                        constraints:
                                                            const BoxConstraints(
                                                              maxHeight: 200,
                                                            ),
                                                      ),
                                                  debounceDuration:
                                                      const Duration(
                                                        milliseconds: 300,
                                                      ),
                                                )
                                                : TextFormField(
                                                  controller: dropOffController,
                                                  enabled: false,
                                                  decoration:
                                                      const InputDecoration(
                                                        labelText: 'End-Point',
                                                        hintText: 'Destination',
                                                        border:
                                                            OutlineInputBorder(),
                                                        contentPadding:
                                                            EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 15,
                                                            ),
                                                        suffixIcon: Icon(
                                                          Icons.lock,
                                                        ),
                                                      ),
                                                  validator: (value) {
                                                    if (value == null ||
                                                        value.isEmpty) {
                                                      return 'Please enter a destination';
                                                    }
                                                    return null;
                                                  },
                                                ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton(
                                      onPressed: _showRoutes,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: mainButtonColor,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15.0,
                                          horizontal: 20.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            2.0,
                                          ),
                                        ),
                                        elevation: 2.0,
                                      ),
                                      child: const Text(
                                        'View Routes',
                                        style: TextStyle(
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isMapVisible) ...[
                                    const SizedBox(height: 16),
                                    Container(
                                      height: 300,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 300,
                                          child: Stack(
                                            children: [
                                              GoogleMap(
                                                initialCameraPosition:
                                                    initialCameraPosition,
                                                markers: markers,
                                                polylines: Set<Polyline>.of(
                                                  polylines.values,
                                                ),
                                                onMapCreated: (controller) {
                                                  mapController = controller;
                                                  updateMapTheme(controller);
                                                },
                                                zoomControlsEnabled: true,
                                                mapToolbarEnabled: false,
                                                myLocationButtonEnabled: false,
                                              ),
                                              if (isLoading)
                                                SizedBox(
                                                  width: double.infinity,
                                                  height: 300,
                                                  child: Container(
                                                    color: Colors.black
                                                        .withOpacity(0.5),
                                                    child: const Center(
                                                      child:
                                                          CircularProgressIndicator(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (routeOptions.isNotEmpty) ...[
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Select Route:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      SizedBox(
                                        height: 120,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: routeOptions.length,
                                          itemBuilder: (context, index) {
                                            return GestureDetector(
                                              onTap: () => _selectRoute(index),
                                              child: Container(
                                                width: 160,
                                                margin: const EdgeInsets.only(
                                                  right: 10,
                                                ),
                                                padding: const EdgeInsets.all(
                                                  10,
                                                ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color:
                                                        index ==
                                                                selectedRouteIndex
                                                            ? Colors.blue
                                                            : Colors
                                                                .grey
                                                                .shade300,
                                                    width:
                                                        index ==
                                                                selectedRouteIndex
                                                            ? 2
                                                            : 1,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color:
                                                      index ==
                                                              selectedRouteIndex
                                                          ? Colors.blue
                                                              .withOpacity(0.1)
                                                          : Colors.grey.shade50,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      'Route ${index + 1}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            index ==
                                                                    selectedRouteIndex
                                                                ? Colors.blue
                                                                : Colors
                                                                    .black87,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 5),
                                                    Text(
                                                      'Duration: ${routeDurations[index]}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            index ==
                                                                    selectedRouteIndex
                                                                ? Colors
                                                                    .blue
                                                                    .shade800
                                                                : Colors
                                                                    .black54,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Distance: ${routeDistances[index]}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            index ==
                                                                    selectedRouteIndex
                                                                ? Colors
                                                                    .blue
                                                                    .shade800
                                                                : Colors
                                                                    .black54,
                                                      ),
                                                    ),
                                                    if (index ==
                                                        selectedRouteIndex) ...[
                                                      const SizedBox(height: 5),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 3,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                10,
                                                              ),
                                                        ),
                                                        child: const Text(
                                                          'Selected',
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            DateTime?
                                            pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate:
                                                  DateTime.now(), // Restrict to today and future
                                              lastDate: DateTime(2100),
                                              
                                            );

                                            if (pickedDate != null) {
                                              String formattedDate =
                                                  "${pickedDate.day.toString().padLeft(2, '0')}/"
                                                  "${pickedDate.month.toString().padLeft(2, '0')}/"
                                                  "${pickedDate.year}";
                                              dateController.text =
                                                  formattedDate;
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: CustomInputField(
                                              controller: dateController,
                                              label: 'Date',
                                              hintText: 'DD/MM/YYYY',
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please select a date';
                                                }
                                                return null;
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.access_time,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: CustomDropdownField(
                                          label:
                                              isWSO2Start
                                                  ? 'Start Time'
                                                  : 'Arriving Time',
                                          hintText:
                                              isWSO2Start
                                                  ? '17:00:00'
                                                  : '08:00:00',
                                          options: _getTimeOptions(),
                                          value: selectedTime,
                                          onChanged: (value) {
                                            setState(() {
                                              selectedTime = value;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Please select a time';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 20),
                                  CustomButton(
                                    text: 'Post Ride',
                                    onPressed: _postRide,
                                    height: 60,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isPosting)
            Center(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4.0,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
