import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/services/ride_services.dart';
import 'package:mobile_frontend/views/common/select_location.dart';
import 'package:mobile_frontend/views/passenger/ride_list.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geocoding/geocoding.dart';

class FindARideScreen extends StatefulWidget {
  const FindARideScreen({Key? key}) : super(key: key);

  @override
  State<FindARideScreen> createState() => _FindARideScreenState();
}

class _FindARideScreenState extends State<FindARideScreen> {
  String? direction = 'From WSO2';
  String? selectedTime;
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = const FlutterSecureStorage();
  bool _isPosting = false;

  String? locationPlaceId;

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
      locationController.text = "";
      direction = 'From WSO2';
      selectedTime = null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting address: $e')),
      );
    }
    return null;
  }

  Future<void> _selectLocation() async {
    final LatLng? selectedLocation = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectLocation(
          initialLocation: _selectedLocationFromLatLng(locationController.text),
        ),
      ),
    );

    if (selectedLocation != null) {
      String? address = await _getAddressFromLatLng(
        selectedLocation.latitude,
        selectedLocation.longitude,
      );
      setState(() {
        locationController.text = address ??
            "Selected Location (${selectedLocation.latitude}, ${selectedLocation.longitude})";
        locationPlaceId = null;
      });
    }
  }

  LatLng? _selectedLocationFromLatLng(String address) {
    if (address.toLowerCase() == wso2Address.toLowerCase()) {
      return wso2Coordinates;
    }
    return null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching places: $e')),
      );
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

  bool _isTimeInRange(String rideTime, String timeRange) {
    final parts = timeRange.split('-');
    if (parts.length != 2) return false;

    final startTimeStr = parts[0];
    final endTimeStr = parts[1];

    final rideParts = rideTime.split(':');
    if (rideParts.length < 2) return false;
    final rideHour = int.parse(rideParts[0]);
    final rideMinute = int.parse(rideParts[1]);

    final startParts = startTimeStr.split(':');
    final endParts = endTimeStr.split(':');
    if (startParts.length < 2 || endParts.length < 2) return false;

    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);

    final rideMinutes = rideHour * 60 + rideMinute;
    final startMinutes = startHour * 60 + startMinute;
    final endMinutes = endHour * 60 + endMinute;

    return rideMinutes >= startMinutes && rideMinutes <= endMinutes;
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

    double a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(deltaLng / 2) * math.sin(deltaLng / 2);
    double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  Future<bool> doesRideMatchPassengerPickup(
    String pickupAddress,
    Map<String, dynamic> ride,
  ) async {
    try {
      List<Location> locations = await locationFromAddress(pickupAddress);
      if (locations.isEmpty) {
        print('Could not geocode pickup address: $pickupAddress');
        return false;
      }
      LatLng pickupPoint = LatLng(
        locations[0].latitude,
        locations[0].longitude,
      );

      List<dynamic> polylineData = ride['route']['polyline'];
      List<LatLng> polyline = polylineData.map((point) {
        return LatLng(
          double.parse(point['latitude']),
          double.parse(point['longitude']),
        );
      }).toList();

      const double maxDistanceMeters = 200.0;
      return isPointNearPolyline(pickupPoint, polyline, maxDistanceMeters);
    } catch (e) {
      print('Error checking ride match: $e');
      return false;
    }
  }

  Future<LatLng?> _getWaypointLatLng(String address) async {
    if (address.toLowerCase() == wso2Address.toLowerCase()) {
      return wso2Coordinates;
    }
    if (locationPlaceId != null) {
      return await getPlaceDetails(locationPlaceId!);
    }
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        return LatLng(locations[0].latitude, locations[0].longitude);
      }
    } catch (e) {
      print('Error geocoding waypoint address: $e');
    }
    return null;
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

      bool waytowork = direction == 'To WSO2';

      final rideData = {
        'date': dateController.text,
        'waytowork': waytowork,
      };

      final response = await RideService.rideSearch(rideData, token);
      final responseBody = jsonDecode(response.body);

      print(responseBody['count']);

      setState(() {
        _isPosting = false;
      });

      if (response.statusCode == 200) {
        List<dynamic> rides = responseBody['rides'];
        List<Map<String, dynamic>> matchingRides = [];

        String pickupAddress = locationController.text;
        LatLng? waypointLatLng = await _getWaypointLatLng(pickupAddress);

        for (var ride in rides) {
          if (ride['date'] == dateController.text &&
              (selectedTime == null || _isTimeInRange(ride['time'], selectedTime!))) {
            bool matches = await doesRideMatchPassengerPickup(pickupAddress, ride);
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

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RideListScreen(
                rides: matchingRides,
                waypoint: locationController.text,
                waypointLatLng: waypointLatLng,
                waytowork: direction == 'To WSO2',
                date: dateController.text,
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'No rides for your route',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(
                top: 50.0,
                left: 16.0,
                right: 16.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              duration: const Duration(seconds: 4),
              elevation: 8.0,
            ),
          );
        }
      } else {
        final errorMessage = responseBody['message'] ?? 'Failed to search rides';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isPosting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching rides: $e')),
      );
    }
  }


  @override
  void dispose() {
    locationController.dispose();
    dateController.dispose();
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
                                        Icons.location_on_outlined,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: DropdownButtonFormField<String>(
                                          value: direction,
                                          isExpanded: true,
                                          decoration: InputDecoration(
                                            contentPadding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: Colors.grey.shade300,
                                                width: 1,
                                              ),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: mainButtonColor,
                                                width: 2,
                                              ),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey.shade50,
                                            labelText: 'Direction',
                                            labelStyle: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 16,
                                            ),
                                          ),
                                          dropdownColor: Colors.white,
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          icon: Icon(
                                            Icons.arrow_drop_down,
                                            color: mainButtonColor,
                                            size: 24,
                                          ),
                                          items: [
                                            DropdownMenuItem(
                                              value: 'From WSO2',
                                              child: Text(
                                                'From WSO2',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                  fontWeight: direction == 'From WSO2'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                            DropdownMenuItem(
                                              value: 'To WSO2',
                                              child: Text(
                                                'To WSO2',
                                                style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 16,
                                                  fontWeight: direction == 'To WSO2'
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ],
                                          onChanged: (value) {
                                            setState(() {
                                              direction = value;
                                              locationController.text = "";
                                              locationPlaceId = null;
                                              selectedTime = null;
                                            });
                                          },
                                          validator: (value) {
                                            if (value == null || value.isEmpty) {
                                              return 'Please select a direction';
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
                                        Icons.location_on,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                     Expanded(
                                        child: TypeAheadField<
                                          Map<String, dynamic>
                                        >(
                                          textFieldConfiguration:
                                              TextFieldConfiguration(
                                                controller: locationController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      direction == 'To WSO2'
                                                          ? 'Pickup Location'
                                                          : 'Drop-Off Location',
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
                                                      Icons.location_on_sharp,
                                                    ),
                                                    onPressed: _selectLocation,
                                                  ),
                                                ),
                                              ),
                                          suggestionsCallback: (pattern) async {
                                            if (pattern.length >= 3) {
                                              return await searchSriLankaPlaces(
                                                pattern,
                                              );
                                            }
                                            return [];
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
                                              locationController.text =
                                                  suggestion['description'];
                                              locationPlaceId =
                                                  suggestion['place_id'];
                                            });
                                          },
                                          noItemsFoundBuilder:
                                              (context) => const Padding(
                                                padding: EdgeInsets.all(8.0),
                                                child: Text(
                                                  'No locations found',
                                                ),
                                              ),
                                          suggestionsBoxDecoration:
                                              SuggestionsBoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                elevation: 4,
                                                color: Colors.white,
                                                constraints:
                                                    const BoxConstraints(
                                                      maxHeight: 200,
                                                    ),
                                              ),
                                          debounceDuration: const Duration(
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
                                        Icons.calendar_today,
                                        color: Color(0x9C002B5B),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            DateTime? pickedDate = await showDatePicker(
                                              context: context,
                                              initialDate: DateTime.now(),
                                              firstDate: DateTime.now(),
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
                                              validator: (value) {
                                                if (value == null || value.isEmpty) {
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
                                        child: GestureDetector(
                                          onTap: () async {
                                            TimeOfDay? startTime = await showTimePicker(
                                              context: context,
                                              initialTime: TimeOfDay.now(),
                                              builder: (BuildContext context, Widget? child) {
                                                return Transform.scale(
                                                  scale: 1,
                                                  child: Dialog(
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(16),
                                                    ),
                                                    child: Container(
                                                      padding: const EdgeInsets.all(2),
                                                      constraints: BoxConstraints(
                                                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                                                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                                                      ),
                                                      child: child,
                                                    ),
                                                  ),
                                                );
                                              },
                                            );

                                            if (startTime != null) {
                                              TimeOfDay? endTime = await showTimePicker(
                                                context: context,
                                                initialTime: TimeOfDay(
                                                  hour: startTime.hour + 1,
                                                  minute: startTime.minute,
                                                ),
                                                builder: (BuildContext context, Widget? child) {
                                                  return Transform.scale(
                                                    scale: 1,
                                                    child: Dialog(
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(16),
                                                      ),
                                                      child: Container(
                                                        padding: const EdgeInsets.all(2),
                                                        constraints: BoxConstraints(
                                                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                                                          maxHeight: MediaQuery.of(context).size.height * 0.6,
                                                        ),
                                                        child: child,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );

                                              if (endTime != null) {
                                                setState(() {
                                                  selectedTime =
                                                      "${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}-"
                                                      "${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}";
                                                });
                                              }
                                            }
                                          },
                                          child: AbsorbPointer(
                                            child: CustomInputField(
                                              controller: TextEditingController(text: selectedTime),
                                              label: direction == 'From WSO2' ? 'Start Time Range' : 'Arriving Time Range',
                                              hintText: 'HH:MM-HH:MM',
                                              validator: null,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  CustomButton(
                                    text: 'Find Ride',
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