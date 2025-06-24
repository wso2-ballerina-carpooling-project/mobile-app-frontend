import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_frontend/services/ride_services.dart';
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
    Future.delayed(const Duration(milliseconds: 500), () {
      _showRoutes();
    });
  }

  Future<void> _determinePosition() async {
    setState(() {
      pickUpController.text = wso2Address;
      dropOffController.text = "Pettah, Colombo, Sri Lanka";
      isWSO2Start = true;
    });
  }

  Future<void> _getAddressFromLatLng(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '${place.street}, ${place.locality}';
        if (!isWSO2Start) {
          pickUpController.text = address;
        }
      }
    } catch (e) {
      print('Error getting address: $e');
    }
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

  Future<void> _showRoutes() async {
    setState(() {
      isLoading = true;
      isMapVisible = true;
    });

    try {
      LatLng? originLatLng;
      LatLng? destLatLng;

      if (pickUpPlaceId != null) {
        originLatLng = await getPlaceDetails(pickUpPlaceId!);
      }

      if (dropOffPlaceId != null) {
        destLatLng = await getPlaceDetails(dropOffPlaceId!);
      }

      if (originLatLng == null) {
        if (pickUpController.text.isEmpty ||
            pickUpController.text == wso2Address) {
          originLatLng = wso2Coordinates;
          pickUpController.text = wso2Address;
        } else {
          try {
            List<Location> locations = await locationFromAddress(
              "${pickUpController.text}, Sri Lanka",
            );
            if (locations.isNotEmpty) {
              originLatLng = LatLng(
                locations[0].latitude,
                locations[0].longitude,
              );
            } else {
              originLatLng = wso2Coordinates;
            }
          } catch (e) {
            originLatLng = wso2Coordinates;
          }
        }
      }

      if (destLatLng == null) {
        if (dropOffController.text.isEmpty || !isWSO2Start) {
          destLatLng = wso2Coordinates;
          dropOffController.text = wso2Address;
        } else {
          try {
            List<Location> locations = await locationFromAddress(
              "${dropOffController.text}, Sri Lanka",
            );
            if (locations.isNotEmpty) {
              destLatLng = LatLng(
                locations[0].latitude,
                locations[0].longitude,
              );
            } else {
              destLatLng = const LatLng(6.9344, 79.8428);
            }
          } catch (e) {
            destLatLng = const LatLng(6.9344, 79.8428);
          }
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

      LatLng originLatLngMark = originLatLng;
      LatLng desLat = destLatLng;

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

  Future<void> _postRide() async {
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
        'waytowork' : waytowork,
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride posted successfully')),
        );
        Navigator.pop(context);
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Failed to post ride';
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
      ).showSnackBar(SnackBar(content: Text('Error posting ride: $e')));
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
                                        _showRoutes();
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
                                          return 'Please enter a starting point';
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
                                                      labelText: 'End-Point',
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
                                                _showRoutes();
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
                                                labelText: 'End-Point',
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
                              CustomButton(
                                text: 'View Route Options',
                                onPressed: _showRoutes,
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
                                          zoomControlsEnabled: true,
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
                                text: 'Post Ride',
                                onPressed: _postRide,
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
