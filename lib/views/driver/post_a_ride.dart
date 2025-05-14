import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/map_services.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

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

  // Place search controllers
  final FocusNode pickUpFocusNode = FocusNode();
  final FocusNode dropOffFocusNode = FocusNode();

  // Google Maps Controller
  GoogleMapController? mapController;
  CameraPosition initialCameraPosition = const CameraPosition(
    target: LatLng(0, 0), // Will be updated with user's location
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

  @override
  void initState() {
    super.initState();
    _determinePosition();
    // Load the routes automatically after a brief delay to allow the screen to initialize
    Future.delayed(const Duration(milliseconds: 500), () {
      _showRoutes();
    });
  }

  // Set initial map position to show Sri Lanka
  Future<void> _determinePosition() async {
    // Use Moratuwa coordinates for initial position
    setState(() {
      initialCameraPosition = const CameraPosition(
        target: LatLng(6.7734, 79.8825), // Moratuwa
        zoom: 12.0,
      );

      // Pre-fill pickup location
      pickUpController.text = "Moratuwa, Sri Lanka";
      dropOffController.text = "Pettah, Colombo, Sri Lanka";
    });
  }

  // Get address from coordinates
  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}';
        pickUpController.text = address;
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  // Get coordinates from address
  Future<LatLng?> _getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations[0].latitude, locations[0].longitude);
      }
    } catch (e) {
      print('Error getting coordinates: $e');
    }
    return null;
  }

  // Store selected place IDs
  String? pickUpPlaceId;
  String? dropOffPlaceId;

  // Show routes on map
  Future<void> _showRoutes() async {
    setState(() {
      isLoading = true;
      isMapVisible = true;
    });

    try {
      LatLng? originLatLng;
      LatLng? destLatLng;

      // Try to get coordinates from place IDs first if available
      if (pickUpPlaceId != null) {
        originLatLng = await getPlaceDetails(pickUpPlaceId!);
      }

      if (dropOffPlaceId != null) {
        destLatLng = await getPlaceDetails(dropOffPlaceId!);
      }

      // Fall back to hardcoded coordinates or geocoding
      if (originLatLng == null) {
        if (pickUpController.text.isEmpty) {
          // Default to Moratuwa if empty
          originLatLng = const LatLng(6.7734, 79.8825);
          pickUpController.text = "Moratuwa, Sri Lanka";
        } else {
          // Try geocoding the address
          try {
            List<Location> locations = await locationFromAddress(
              "${pickUpController.text}, Sri Lanka", // Append Sri Lanka to focus search
            );
            if (locations.isNotEmpty) {
              originLatLng = LatLng(
                locations[0].latitude,
                locations[0].longitude,
              );
            } else {
              // Default to Moratuwa if geocoding fails
              originLatLng = const LatLng(6.7734, 79.8825);
            }
          } catch (e) {
            originLatLng = const LatLng(6.7734, 79.8825);
          }
        }
      }

      if (destLatLng == null) {
        if (dropOffController.text.isEmpty) {
          // Default to Pettah if empty
          destLatLng = const LatLng(6.9344, 79.8428);
          dropOffController.text = "Pettah, Colombo, Sri Lanka";
        } else {
          // Try geocoding the address
          try {
            List<Location> locations = await locationFromAddress(
              "${dropOffController.text}, Sri Lanka", // Append Sri Lanka to focus search
            );
            if (locations.isNotEmpty) {
              destLatLng = LatLng(
                locations[0].latitude,
                locations[0].longitude,
              );
            } else {
              // Default to Pettah if geocoding fails
              destLatLng = const LatLng(6.9344, 79.8428);
            }
          } catch (e) {
            destLatLng = const LatLng(6.9344, 79.8428);
          }
        }
      }

      // Set the camera position to show both markers
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

      LatLng originLatLngMark = originLatLng;
      LatLng desLat = destLatLng;

      // Add markers
      setState(() {
        markers = {
          Marker(
            markerId: const MarkerId('origin'),
            position: originLatLngMark,
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
            position: desLat,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(
              title: 'Drop-off',
              snippet: dropOffController.text,
            ),
          ),
        };

        // Animate camera to show both markers
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

  // Get directions from Google Directions API
  Future<void> _getDirections(LatLng origin, LatLng destination) async {
    const apiKey =
        'AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE'; // Replace with your actual API key
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

          // Clear previous routes
          setState(() {
            polylines.clear();
            routeOptions.clear();
            routeDurations.clear();
            routeDistances.clear();
          });

          // Process each route
          for (int i = 0; i < routes.length; i++) {
            final route = routes[i];
            final legs = route['legs'][0];
            final steps = legs['steps'] as List;
            final String duration = legs['duration']['text'];
            final String distance = legs['distance']['text'];

            // Store route info
            routeDurations.add(duration);
            routeDistances.add(distance);

            // Decode polyline
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

          // If no routes were selected, select the first one
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

  // Select a route
  void _selectRoute(int index) {
    setState(() {
      selectedRouteIndex = index;

      // Update polyline colors
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

  List<String> generateTimes() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final hh = hour.toString().padLeft(2, '0');
        final mm = minute.toString().padLeft(2, '0');
        times.add('$hh:$mm:00');
      }
    }
    return times;
  }

  @override
  void dispose() {
    pickUpController.dispose();
    dropOffController.dispose();
    dateController.dispose();
    vehicleRegController.dispose();
    pickUpFocusNode.dispose();
    dropOffFocusNode.dispose();
    mapController?.dispose();
    super.dispose();
  }

  // Search for Sri Lankan places
  // Future<List<Map<String, dynamic>>> searchSriLankaPlaces(String query) async {
  //   if (query.length < 3) return [];

  //   const apiKey =
  //       'AIzaSyBJToHkeu0EhfzRM64HXhCg2lil_Kg9pSE'; // Replace with your actual API key
  //   final url = Uri.parse(
  //     'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
  //     'input=$query' // This restricts results to Sri Lanka using country code
  //     '&components=country:lk'
  //     '&key=$apiKey',
  //   );

  //   try {
  //     final response = await http.get(url);
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);

  //       if (data['status'] == 'OK') {
  //         final predictions = data['predictions'] as List;
  //         return predictions.map((prediction) {
  //           return {
  //             'description': prediction['description'],
  //             'place_id': prediction['place_id'],
  //           };
  //         }).toList();
  //       }
  //     }
  //     return [];
  //   } catch (e) {
  //     print('Error searching places: $e');
  //     return [];
  //   }
  // }




  // Get place details by place ID
  Future<LatLng?> getPlaceDetails(String placeId) async {
    const apiKey =
        'AIzaSyC8GlueGNwtpZjPUjF6SWnxUHyC5GA82KE'; // Replace with your actual API key
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Post a Ride',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Card
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

                        // Form Card
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
                              // Starting point
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    color: Color(0x9C002B5B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TypeAheadFormField(
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                            controller: pickUpController,
                                            focusNode: pickUpFocusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'Starting-Point',
                                              hintText: 'Your Location',
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 15,
                                                  ),
                                            ),
                                          ),
                                      suggestionsCallback: (pattern) async {
                                        return await MapServices.searchSriLankaPlaces(
                                          pattern,
                                        );
                                      },
                                      itemBuilder: (context, suggestion) {
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.location_on,
                                          ),
                                          title: Text(
                                            suggestion['description'],
                                          ),
                                          subtitle: const Text('Sri Lanka'),
                                        );
                                      },
                                      onSuggestionSelected: (suggestion) {
                                        pickUpController.text =
                                            suggestion['description'];
                                        pickUpPlaceId = suggestion['place_id'];
                                      },
                                      noItemsFoundBuilder:
                                          (context) => const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'No locations found in Sri Lanka.',
                                              style: TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // End point
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    color: Color(0x9C002B5B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TypeAheadFormField(
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                            controller: dropOffController,
                                            focusNode: dropOffFocusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'End-Point',
                                              hintText: 'Destination',
                                              border: OutlineInputBorder(),
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                    horizontal: 20,
                                                    vertical: 15,
                                                  ),
                                            ),
                                          ),
                                      suggestionsCallback: (pattern) async {
                                        return await MapServices.searchSriLankaPlaces(
                                          pattern,
                                        );
                                      },
                                      itemBuilder: (context, suggestion) {
                                        return ListTile(
                                          leading: const Icon(
                                            Icons.location_on,
                                          ),
                                          title: Text(
                                            suggestion['description'],
                                          ),
                                          subtitle: const Text('Sri Lanka'),
                                        );
                                      },
                                      onSuggestionSelected: (suggestion) {
                                        dropOffController.text =
                                            suggestion['description'];
                                        dropOffPlaceId = suggestion['place_id'];
                                      },
                                      noItemsFoundBuilder:
                                          (context) => const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'No locations found in Sri Lanka.',
                                            ),
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // View Routes Button
                              CustomButton(
                                text: 'View Route Options',
                                onPressed: _showRoutes,
                              ),

                              // Map for displaying routes
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
                                    child: Stack(
                                      children: [
                                        GoogleMap(
                                          initialCameraPosition:
                                              initialCameraPosition,
                                          markers: markers,
                                          polylines: Set<Polyline>.of(
                                            polylines.values,
                                          ),
                                          onMapCreated: (
                                            GoogleMapController controller,
                                          ) {
                                            mapController = controller;
                                          },
                                          zoomControlsEnabled: false,
                                          mapToolbarEnabled: false,
                                          myLocationButtonEnabled: false,
                                        ),
                                        if (isLoading)
                                          Container(
                                            color: Colors.black.withOpacity(
                                              0.5,
                                            ),
                                            child: const Center(
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Route options
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
                                            padding: const EdgeInsets.all(10),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color:
                                                    index == selectedRouteIndex
                                                        ? Colors.blue
                                                        : Colors.grey.shade300,
                                                width:
                                                    index == selectedRouteIndex
                                                        ? 2
                                                        : 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              color:
                                                  index == selectedRouteIndex
                                                      ? Colors.blue.withOpacity(
                                                        0.1,
                                                      )
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
                                                    fontWeight: FontWeight.bold,
                                                    color:
                                                        index ==
                                                                selectedRouteIndex
                                                            ? Colors.blue
                                                            : Colors.black87,
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
                                                            : Colors.black54,
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
                                                            : Colors.black54,
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

                              // Date
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0x9C002B5B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: dateController,
                                      label: 'Date',
                                      hintText: 'DD/MM/YYYY',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Start Time
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
                                      label: 'Arriving Time/Start Time',
                                      hintText: '08:00:00',
                                      options: generateTimes(),
                                      value: selectedTime,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedTime = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Return Time
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
                                      label: 'Trip Start Time',
                                      hintText: '07:00:00',
                                      options: generateTimes(),
                                      value: selectedReturnTime,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedReturnTime = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Vehicle Registration Number
                              Row(
                                children: [
                                  const Icon(
                                    Icons.directions_car,
                                    color: Color(0x9C002B5B),
                                    size: 50,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: vehicleRegController,
                                      enabled: isVehicleRegEditable,
                                      decoration: const InputDecoration(
                                        labelText: 'CBL 5680',
                                        hintText: 'Vehicle Reg. No.',
                                        border: InputBorder.none,
                                        filled: true,
                                        fillColor: Color(0xFFF2F2F2),
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 8,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Colors.black,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Color(0xFF0A0E2A),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isVehicleRegEditable = true;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Post Ride Button
                              CustomButton(
                                text: 'Post Ride',
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    // Get the selected route data
                                    String routeInfo = '';
                                    if (selectedRouteIndex <
                                        routeDurations.length) {
                                      routeInfo =
                                          'Route ${selectedRouteIndex + 1}: ${routeDurations[selectedRouteIndex]}, ${routeDistances[selectedRouteIndex]}';
                                    }

                                    print('Posting ride...');
                                    print('Pick-Up: ${pickUpController.text}');
                                    print(
                                      'Drop-Off: ${dropOffController.text}',
                                    );
                                    print('Date: ${dateController.text}');
                                    print('Time selected: $selectedTime');
                                    print('Return Time: $selectedReturnTime');
                                    print(
                                      'Vehicle Reg: ${vehicleRegController.text}',
                                    );
                                    print('Selected Route: $routeInfo');
                                  } else {
                                    print(
                                      'Please fill in all required fields.',
                                    );
                                  }
                                },
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
    );
  }
}
