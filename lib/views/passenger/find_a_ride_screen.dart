import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/passenger/ride_list.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'dart:math' as math;
import 'package:flutter_typeahead/flutter_typeahead.dart';

class FindARideScreen extends StatefulWidget {
  const FindARideScreen({Key? key}) : super(key: key);

  @override
  State<FindARideScreen> createState() => _FindARideScreen();
}

class _FindARideScreen extends State<FindARideScreen> {
  String? selectedTime;
  final TextEditingController pickUpController = TextEditingController();
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController vehicleRegController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();
  bool _isPosting = false;

  // Place search controllers
  final FocusNode pickUpFocusNode = FocusNode();
  final FocusNode dropOffFocusNode = FocusNode();

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

  // WSO2 specific variables
  final String wso2Address = "WSO2, Bauddhaloka Mawatha, Colombo, Sri Lanka";
  final LatLng wso2Coordinates = const LatLng(
    6.8953284,
    79.8546711,
  ); // WSO2 coordinates
  bool isWSO2Start = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
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

  Future<void> _determinePosition() async {
    setState(() {
      pickUpController.text = wso2Address;
      dropOffController.text = "Pettah, Colombo, Sri Lanka";
      isWSO2Start = true;
    });
  }

  

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

  String? pickUpPlaceId;
  String? dropOffPlaceId;

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
    super.dispose();
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
        }
      }
      return [];
    } catch (e) {
      print('Error searching places: $e');
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                        'Find a Ride',
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
                                    child: TypeAheadFormField(
                                      textFieldConfiguration:
                                          TextFieldConfiguration(
                                            controller: pickUpController,
                                            focusNode: pickUpFocusNode,
                                            decoration: const InputDecoration(
                                              labelText: 'Pick-Up Location',
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
                                        return await searchSriLankaPlaces(
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
                                          (context) => const Padding(
                                            padding: EdgeInsets.all(8.0),
                                            child: Text(
                                              'No locations found in Sri Lanka.',
                                              style: TextStyle(
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a pickup location';
                                        }
                                        return null;
                                      },
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
                                            ? TypeAheadFormField(
                                              textFieldConfiguration:
                                                  TextFieldConfiguration(
                                                    controller:
                                                        dropOffController,
                                                    focusNode: dropOffFocusNode,
                                                    decoration: const InputDecoration(
                                                      labelText:
                                                          'Drop-Off Location',
                                                      hintText: 'Destination',
                                                      border:
                                                          OutlineInputBorder(),
                                                      contentPadding:
                                                          EdgeInsets.symmetric(
                                                            horizontal: 20,
                                                            vertical: 15,
                                                          ),
                                                    ),
                                                  ),
                                              suggestionsCallback: (
                                                pattern,
                                              ) async {
                                                return await searchSriLankaPlaces(
                                                  pattern,
                                                );
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
                                                });
                                              },
                                              noItemsFoundBuilder:
                                                  (context) => const Padding(
                                                    padding: EdgeInsets.all(
                                                      8.0,
                                                    ),
                                                    child: Text(
                                                      'No locations found in Sri Lanka.',
                                                    ),
                                                  ),
                                              validator: (value) {
                                                if (value == null ||
                                                    value.isEmpty) {
                                                  return 'Please enter a destination';
                                                }
                                                return null;
                                              },
                                            )
                                            : TextFormField(
                                              controller: dropOffController,
                                              enabled: false,
                                              focusNode: dropOffFocusNode,
                                              decoration: InputDecoration(
                                                labelText: 'Drop-Off Location',
                                                hintText: 'Destination',
                                                border:
                                                    const OutlineInputBorder(),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 20,
                                                      vertical: 15,
                                                    ),
                                                suffixIcon: const Icon(
                                                  Icons.lock,
                                                ),
                                              ),
                                              readOnly: true,
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
                                        DateTime? pickedDate =
                                            await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime(2000),
                                              lastDate: DateTime(2100),
                                            );

                                        if (pickedDate != null) {
                                          String formattedDate =
                                              "${pickedDate.day.toString().padLeft(2, '0')}/"
                                              "${pickedDate.month.toString().padLeft(2, '0')}/"
                                              "${pickedDate.year}";
                                          dateController.text = formattedDate;
                                        }
                                      },
                                      child: AbsorbPointer(
                                        child: CustomInputField(
                                          controller: dateController,
                                          label: 'Date',
                                          hintText: 'DD/MM/YYYY',
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
                                              : 'End Time',
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
                              CustomButton(
                                text: 'Find Ride',
                                onPressed: _searchRide,
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
