import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/common/select_location.dart';
import 'package:mobile_frontend/views/passenger/ride_list.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';

class FindARideScreen extends StatefulWidget {
  const FindARideScreen({Key? key}) : super(key: key);

  @override
  State<FindARideScreen> createState() => _FindARideScreenState();
}

class _FindARideScreenState extends State<FindARideScreen> {
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
   bool isPointNearPolyline(
    LatLng point,
    List<LatLng> polyline,
    double maxDistanceMeters,
  ) {
    for (var polyPoint in polyline) {
      double distance = _calculateDistance(point, polyPoint);
      if (distance <= maxDistanceMeters) {
        return true;
      } 
    }
    return false;
  }
    double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    double lat1 = point1.latitude * math.pi / 180;
    double lat2 = point2.latitude * math.pi / 180;
    double deltaLat = (point2.latitude - point1.latitude) * math.pi / 180;
    double deltaLng = (point2.longitude - point1.longitude) * math.pi / 180;

    double a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }



  Future<bool> doesRideMatchPassengerPickup(
    String pickupAddress,
    Map<String, dynamic> ride,
  ) async {
    try {
      // Convert pickup address to coordinates
      List<Location> locations = await locationFromAddress(pickupAddress);

      print(locations);
      if (locations.isEmpty) {
        print('Could not geocode pickup address: $pickupAddress');
        return false;
      }
      LatLng pickupPoint = LatLng(
        locations[0].latitude,
        locations[0].longitude,
      );

      // Extract polyline from ride
      List<dynamic> polylineData = ride['route']['polyline'];
      List<LatLng> polyline =
          polylineData.map((point) {
            return LatLng(
              double.parse(point['latitude']),
              double.parse(point['longitude']),
            );
          }).toList();

      // Check if pickup point is near the polyline (within 100 meters)
      const double maxDistanceMeters = 200.0;
      return isPointNearPolyline(pickupPoint, polyline, maxDistanceMeters);
    } catch (e) {
      print('Error checking ride match: $e');
      return false;
    }
  }



  Future<void> _searchRide() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        throw Exception('No authentication token found');
      }

      bool waytowork = true;
      if (pickUpController.text ==
          "WSO2, Bauddhaloka Mawatha, Colombo, Sri Lanka") {
        waytowork = false;
      }

      final rideData = {
        'date': dateController.text,
        'time': selectedTime ?? '',
        'waytowork': waytowork,
      };

      final response = await RideService.rideSearch(rideData, token);
      final responseBody = jsonDecode(response.body);

      print(responseBody['count']);

      setState(() {
        _isPosting = false;
      });

      if (response.statusCode == 200) {
        // Assuming response contains a list of rides
        List<dynamic> rides = responseBody['rides'];
        List<Map<String, dynamic>> matchingRides = [];

        // Check each ride for polyline match
        for (var ride in rides) {
          if (ride['date'] == dateController.text &&
              ride['time'] == selectedTime) {
            bool matches;
            if (waytowork) {
              matches = await doesRideMatchPassengerPickup(
                pickUpController.text,
                ride,
              );
            } else {
              print("find in waytoword");
              matches = await doesRideMatchPassengerPickup(
                dropOffController.text,
                ride,
              );
            }
            if (matches) {
              matchingRides.add(ride);
            }
          }
        }

        if (matchingRides.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Found ${matchingRides.length} matching rides'),
            ),
          );

          if (waytowork) {
            
                 Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideListScreen(rides: matchingRides,waypoint : pickUpController.text),
                  ),
                );
            } else {
             Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RideListScreen(rides: matchingRides,waypoint : dropOffController.text),
                  ),
                );
                
            }

         
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No matching rides found')),
          );
        }
      } else {
        final errorMessage =
            responseBody['message'] ?? 'Failed to search rides';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error searching rides: $e')));
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
      backgroundColor: primaryColor,
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
                                'Find a Ride',
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
                                                            'Pickup Location',
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
                                                          'Pickup Location',
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
                                                      labelText: 'Drop-Off Location',
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
                                    onPressed: _searchRide,
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
