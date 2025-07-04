// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:mobile_frontend/config/constant.dart';
// import 'package:mobile_frontend/services/ride_services.dart';
// import 'package:mobile_frontend/views/common/select_location.dart';
// import 'package:mobile_frontend/widgets/custom_input_field.dart';
// import 'package:mobile_frontend/widgets/custom_button.dart';
// import 'package:mobile_frontend/widgets/dropdown_input.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:flutter_polyline_points/flutter_polyline_points.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:flutter_typeahead/flutter_typeahead.dart';

// class RidePostScreen extends StatefulWidget {
//   const RidePostScreen({Key? key}) : super(key: key);

//   @override
//   State<RidePostScreen> createState() => _RidePostScreenState();
// }

// class _RidePostScreenState extends State<RidePostScreen> {
//   String? selectedTime;
//   String? selectedReturnTime;
//   bool isVehicleRegEditable = false;
//   final TextEditingController pickUpController = TextEditingController();
//   final TextEditingController dropOffController = TextEditingController();
//   final TextEditingController dateController = TextEditingController();
//   final TextEditingController vehicleRegController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   final _storage = const FlutterSecureStorage();
//   bool _isPosting = false;
//   bool isPickUpLocked = false;
//   bool isWSO2Start = false;

//   // Google Maps Controller
//   GoogleMapController? mapController;
//   CameraPosition initialCameraPosition = const CameraPosition(
//     target: LatLng(6.7734, 79.8825), // WSO2 coordinates
//     zoom: 14.0,
//   );

//   // Map variables
//   Set<Marker> markers = {};
//   Map<PolylineId, Polyline> polylines = {};
//   List<List<LatLng>> routeOptions = [];
//   int selectedRouteIndex = 0;
//   bool isMapVisible = false;
//   bool isLoading = false;

//   // Route information
//   List<String> routeDurations = [];
//   List<String> routeDistances = [];

//   // WSO2 specific variables
//   final String wso2Address = "WSO2, Bauddhaloka Mawatha, Colombo, Sri Lanka";
//   final LatLng wso2Coordinates = const LatLng(6.8953284, 79.8546711);

//   @override
//   void initState() {
//     super.initState();
//     _determinePosition();
//   }

//   Future<void> _determinePosition() async {
//     setState(() {
//       pickUpController.text = "";
//       dropOffController.text = "";
//       isWSO2Start = true;
//       isPickUpLocked = false;
//     });
//   }

//   Future<void> _selectLocation(bool isPickup) async {
//     final LatLng? selectedLocation = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SelectLocation(
//           initialLocation: isPickup
//               ? _selectedLocationFromLatLng(pickUpController.text)
//               : _selectedLocationFromLatLng(dropOffController.text),
//         ),
//       ),
//     );

//     if (selectedLocation != null) {
//       String? address = await _getAddressFromLatLng(
//         selectedLocation.latitude,
//         selectedLocation.longitude,
//       );
//       setState(() {
//         if (isPickup) {
//           pickUpController.text = address ??
//               "Selected Location (${selectedLocation.latitude}, ${selectedLocation.longitude})";
//           isWSO2Start = pickUpController.text.toLowerCase().contains('wso2');
//           if (!isWSO2Start) {
//             dropOffController.text = wso2Address;
//             isPickUpLocked = true;
//           } else {
//             isPickUpLocked = false;
//           }
//         } else {
//           dropOffController.text = address ??
//               "Selected Location (${selectedLocation.latitude}, ${selectedLocation.longitude})";
//           if (dropOffController.text.toLowerCase() != wso2Address.toLowerCase()) {
//             pickUpController.text = wso2Address;
//             isWSO2Start = true;
//             isPickUpLocked = true;
//           } else {
//             isPickUpLocked = false;
//           }
//         }
//       });
//       _showRoutes();
//     }
//   }

//   Future<void> _selectPlace(String placeId, bool isPickup) async {
//     final LatLng? location = await getPlaceDetails(placeId);
//     if (location != null) {
//       String? address = await _getAddressFromLatLng(location.latitude, location.longitude);
//       setState(() {
//         if (isPickup) {
//           pickUpController.text = address ?? placeId;
//           isWSO2Start = pickUpController.text.toLowerCase().contains('wso2');
//           if (!isWSO2Start) {
//             dropOffController.text = wso2Address;
//             isPickUpLocked = true;
//           } else {
//             isPickUpLocked = false;
//           }
//         } else {
//           dropOffController.text = address ?? placeId;
//           if (dropOffController.text.toLowerCase() != wso2Address.toLowerCase()) {
//             pickUpController.text = wso2Address;
//             isWSO2Start = true;
//             isPickUpLocked = true;
//           } else {
//             isPickUpLocked = false;
//           }
//         }
//       });
//       _showRoutes();
//     }
//   }

//   // Retain your existing methods: _getAddressFromLatLng, _showRoutes, _getDirections, _selectRoute, _getTimeOptions, _postRide, searchSriLankaPlaces, getPlaceDetails
//   // For brevity, they are not repeated here

//   @override
//   void dispose() {
//     pickUpController.dispose();
//     dropOffController.dispose();
//     dateController.dispose();
//     vehicleRegController.dispose();
//     mapController?.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFF0A0E2A),
//       body: Stack(
//         children: [
//           SafeArea(
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 children: [
//                   SizedBox(
//                     height: 60,
//                     child: Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
//                       child: Stack(
//                         children: [
//                           Positioned(
//                             left: 0,
//                             top: 0,
//                             bottom: 0,
//                             child: GestureDetector(
//                               onTap: () => Navigator.pop(context),
//                               child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
//                             ),
//                           ),
//                           const Positioned(
//                             left: 0,
//                             right: 0,
//                             top: 0,
//                             bottom: 0,
//                             child: Center(
//                               child: Text(
//                                 'Post a Ride',
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(
//                                   fontSize: 24,
//                                   color: Colors.white,
//                                   fontWeight: FontWeight.w400,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                   Expanded(
//                     child: SingleChildScrollView(
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               width: MediaQuery.of(context).size.width * 0.5,
//                               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                               decoration: const BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.only(
//                                   topLeft: Radius.circular(16),
//                                   topRight: Radius.circular(16),
//                                 ),
//                               ),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   const Text(
//                                     'Ride Information',
//                                     style: TextStyle(
//                                       fontSize: 18,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                   const SizedBox(height: 4),
//                                   Center(
//                                     child: Container(
//                                       height: 2,
//                                       width: 50,
//                                       color: Colors.blue,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                             Container(
//                               width: double.infinity,
//                               padding: const EdgeInsets.all(16),
//                               decoration: const BoxDecoration(
//                                 color: Colors.white,
//                                 borderRadius: BorderRadius.only(
//                                   bottomLeft: Radius.circular(16),
//                                   bottomRight: Radius.circular(16),
//                                   topRight: Radius.circular(16),
//                                 ),
//                               ),
//                               child: Column(
//                                 children: [
//                                   // Pickup Location Input with TypeAhead
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.location_on, color: Color(0x9C002B5B), size: 20),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: isPickUpLocked
//                                             ? TextFormField(
//                                                 controller: pickUpController,
//                                                 decoration: const InputDecoration(
//                                                   labelText: 'Starting-Point',
//                                                   hintText: 'Your Location',
//                                                   border: OutlineInputBorder(),
//                                                   contentPadding: EdgeInsets.symmetric(
//                                                     horizontal: 20,
//                                                     vertical: 15,
//                                                   ),
//                                                   suffixIcon: Icon(Icons.lock),
//                                                 ),
//                                                 readOnly: true,
//                                                 validator: (value) {
//                                                   if (value == null || value.isEmpty) {
//                                                     return 'Please enter a starting point';
//                                                   }
//                                                   return null;
//                                                 },
//                                               )
//                                             : TypeAheadField<Map<String, dynamic>>(
//                                                 textFieldConfiguration: TextFieldConfiguration(
//                                                   controller: pickUpController,
//                                                   decoration: InputDecoration(
//                                                     labelText: 'Starting-Point',
//                                                     hintText: 'Search or tap map icon',
//                                                     border: const OutlineInputBorder(),
//                                                     contentPadding: const EdgeInsets.symmetric(
//                                                       horizontal: 20,
//                                                       vertical: 15,
//                                                     ),
//                                                     suffixIcon: IconButton(
//                                                       icon: const Icon(Icons.map),
//                                                       onPressed: () => _selectLocation(true),
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 suggestionsCallback: (pattern) async {
//                                                   if (pattern.length >= 3) {
//                                                     return await searchSriLankaPlaces(pattern);
//                                                   }
//                                                   return [];
//                                                 },
//                                                 itemBuilder: (context, suggestion) {
//                                                   return ListTile(
//                                                     title: Text(suggestion['description']),
//                                                   );
//                                                 },
//                                                 onSuggestionSelected: (suggestion) {
//                                                   _selectPlace(suggestion['place_id'], true);
//                                                 },
//                                                 noItemsFoundBuilder: (context) => const Padding(
//                                                   padding: EdgeInsets.all(8.0),
//                                                   child: Text('No locations found'),
//                                                 ),
//                                                 suggestionsBoxDecoration: SuggestionsBoxDecoration(
//                                                   borderRadius: BorderRadius.circular(8),
//                                                   elevation: 4,
//                                                   color: Colors.white,
//                                                 ),
//                                               ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   // Drop-off Location Input with TypeAhead
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.location_on_outlined, color: Color(0x9C002B5B), size: 20),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: isWSO2Start
//                                             ? TypeAheadField<Map<String, dynamic>>(
//                                                 textFieldConfiguration: TextFieldConfiguration(
//                                                   controller: dropOffController,
//                                                   decoration: InputDecoration(
//                                                     labelText: 'End-Point',
//                                                     hintText: 'Search or tap map icon',
//                                                     border: const OutlineInputBorder(),
//                                                     contentPadding: const EdgeInsets.symmetric(
//                                                       horizontal: 20,
//                                                       vertical: 15,
//                                                     ),
//                                                     suffixIcon: IconButton(
//                                                       icon: const Icon(Icons.map),
//                                                       onPressed: () => _selectLocation(false),
//                                                     ),
//                                                   ),
//                                                 ),
//                                                 suggestionsCallback: (pattern) async {
//                                                   if (pattern.length >= 3) {
//                                                     return await searchSriLankaPlaces(pattern);
//                                                   }
//                                                   return [];
//                                                 },
//                                                 itemBuilder: (context, suggestion) {
//                                                   return ListTile(
//                                                     title: Text(suggestion['description']),
//                                                   );
//                                                 },
//                                                 onSuggestionSelected: (suggestion) {
//                                                   _selectPlace(suggestion['place_id'], false);
//                                                 },
//                                                 noItemsFoundBuilder: (context) => const Padding(
//                                                   padding: EdgeInsets.all(8.0),
//                                                   child: Text('No locations found'),
//                                                 ),
//                                                 suggestionsBoxDecoration: SuggestionsBoxDecoration(
//                                                   borderRadius: BorderRadius.circular(8),
//                                                   elevation: 4,
//                                                   color: Colors.white,
//                                                 ),
//                                               )
//                                             : TextFormField(
//                                                 controller: dropOffController,
//                                                 enabled: false,
//                                                 decoration: const InputDecoration(
//                                                   labelText: 'End-Point',
//                                                   hintText: 'Destination',
//                                                   border: OutlineInputBorder(),
//                                                   contentPadding: EdgeInsets.symmetric(
//                                                     horizontal: 20,
//                                                     vertical: 15,
//                                                   ),
//                                                   suffixIcon: Icon(Icons.lock),
//                                                 ),
//                                                 readOnly: true,
//                                                 validator: (value) {
//                                                   if (value == null || value.isEmpty) {
//                                                     return 'Please enter a destination';
//                                                   }
//                                                   return null;
//                                                 },
//                                               ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Align(
//                                     alignment: Alignment.centerRight,
//                                     child: ElevatedButton(
//                                       onPressed: _showRoutes,
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: mainButtonColor,
//                                         foregroundColor: Colors.white,
//                                         padding: const EdgeInsets.symmetric(
//                                           vertical: 15.0,
//                                           horizontal: 20.0,
//                                         ),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius: BorderRadius.circular(2.0),
//                                         ),
//                                         elevation: 2.0,
//                                       ),
//                                       child: const Text(
//                                         'View Routes',
//                                         style: TextStyle(
//                                           fontSize: 16.0,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   ),
//                                   // Retain the rest of the UI (map, route selection, date, time, post button)
//                                   if (isMapVisible) ...[
//                                     const SizedBox(height: 16),
//                                     Container(
//                                       height: 300,
//                                       decoration: BoxDecoration(
//                                         borderRadius: BorderRadius.circular(16),
//                                         border: Border.all(color: Colors.grey.shade300),
//                                       ),
//                                       child: ClipRRect(
//                                         borderRadius: BorderRadius.circular(16),
//                                         child: SizedBox(
//                                           width: double.infinity,
//                                           height: 300,
//                                           child: Stack(
//                                             children: [
//                                               GoogleMap(
//                                                 initialCameraPosition: initialCameraPosition,
//                                                 markers: markers,
//                                                 polylines: Set<Polyline>.of(polylines.values),
//                                                 onMapCreated: (controller) {
//                                                   mapController = controller;
//                                                 },
//                                                 zoomControlsEnabled: true,
//                                                 mapToolbarEnabled: false,
//                                                 myLocationButtonEnabled: false,
//                                               ),
//                                               if (isLoading)
//                                                 SizedBox(
//                                                   width: double.infinity,
//                                                   height: 300,
//                                                   child: Container(
//                                                     color: Colors.black.withOpacity(0.5),
//                                                     child: const Center(
//                                                       child: CircularProgressIndicator(
//                                                         color: Colors.white,
//                                                       ),
//                                                     ),
//                                                   ),
//                                                 ),
//                                             ],
//                                           ),
//                                         ),
//                                       ),
//                                     ),
//                                     if (routeOptions.isNotEmpty) ...[
//                                       const SizedBox(height: 16),
//                                       const Text(
//                                         'Select Route:',
//                                         style: TextStyle(
//                                           fontSize: 16,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                       const SizedBox(height: 8),
//                                       SizedBox(
//                                         height: 120,
//                                         child: ListView.builder(
//                                           scrollDirection: Axis.horizontal,
//                                           itemCount: routeOptions.length,
//                                           itemBuilder: (context, index) {
//                                             return GestureDetector(
//                                               onTap: () => _selectRoute(index),
//                                               child: Container(
//                                                 width: 160,
//                                                 margin: const EdgeInsets.only(right: 10),
//                                                 padding: const EdgeInsets.all(10),
//                                                 decoration: BoxDecoration(
//                                                   border: Border.all(
//                                                     color: index == selectedRouteIndex
//                                                         ? Colors.blue
//                                                         : Colors.grey.shade300,
//                                                     width: index == selectedRouteIndex ? 2 : 1,
//                                                   ),
//                                                   borderRadius: BorderRadius.circular(10),
//                                                   color: index == selectedRouteIndex
//                                                       ? Colors.blue.withOpacity(0.1)
//                                                       : Colors.grey.shade50,
//                                                 ),
//                                                 child: Column(
//                                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                                   mainAxisAlignment: MainAxisAlignment.center,
//                                                   children: [
//                                                     Text(
//                                                       'Route ${index + 1}',
//                                                       style: TextStyle(
//                                                         fontWeight: FontWeight.bold,
//                                                         color: index == selectedRouteIndex
//                                                             ? Colors.blue
//                                                             : Colors.black87,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 5),
//                                                     Text(
//                                                       'Duration: ${routeDurations[index]}',
//                                                       style: TextStyle(
//                                                         fontSize: 12,
//                                                         color: index == selectedRouteIndex
//                                                             ? Colors.blue.shade800
//                                                             : Colors.black54,
//                                                       ),
//                                                     ),
//                                                     const SizedBox(height: 2),
//                                                     Text(
//                                                       'Distance: ${routeDistances[index]}',
//                                                       style: TextStyle(
//                                                         fontSize: 12,
//                                                         color: index == selectedRouteIndex
//                                                             ? Colors.blue.shade800
//                                                             : Colors.black54,
//                                                       ),
//                                                     ),
//                                                     if (index == selectedRouteIndex) ...[
//                                                       const SizedBox(height: 5),
//                                                       Container(
//                                                         padding: const EdgeInsets.symmetric(
//                                                           horizontal: 8,
//                                                           vertical: 3,
//                                                         ),
//                                                         decoration: BoxDecoration(
//                                                           color: Colors.blue,
//                                                           borderRadius: BorderRadius.circular(10),
//                                                         ),
//                                                         child: const Text(
//                                                           'Selected',
//                                                           style: TextStyle(
//                                                             fontSize: 10,
//                                                             color: Colors.white,
//                                                           ),
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ],
//                                                 ),
//                                               ),
//                                             );
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                   const SizedBox(height: 24),
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.calendar_today, color: Color(0x9C002B5B), size: 20),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: GestureDetector(
//                                           onTap: () async {
//                                             DateTime? pickedDate = await showDatePicker(
//                                               context: context,
//                                               initialDate: DateTime.now(),
//                                               firstDate: DateTime(2000),
//                                               lastDate: DateTime(2100),
//                                             );

//                                             if (pickedDate != null) {
//                                               String formattedDate =
//                                                   "${pickedDate.day.toString().padLeft(2, '0')}/"
//                                                   "${pickedDate.month.toString().padLeft(2, '0')}/"
//                                                   "${pickedDate.year}";
//                                               dateController.text = formattedDate;
//                                             }
//                                           },
//                                           child: AbsorbPointer(
//                                             child: CustomInputField(
//                                               controller: dateController,
//                                               label: 'Date',
//                                               hintText: 'DD/MM/YYYY',
//                                             ),
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   const SizedBox(height: 16),
//                                   Row(
//                                     children: [
//                                       const Icon(Icons.access_time, color: Color(0x9C002B5B), size: 20),
//                                       const SizedBox(width: 8),
//                                       Expanded(
//                                         child: CustomDropdownField(
//                                           label: isWSO2Start ? 'Start Time' : 'Arriving Time',
//                                           hintText: isWSO2Start ? '17:00:00' : '08:00:00',
//                                           options: _getTimeOptions(),
//                                           value: selectedTime,
//                                           onChanged: (value) {
//                                             setState(() {
//                                               selectedTime = value;
//                                             });
//                                           },
//                                         ),
//                                       ),
//                                     ],
//                                   ),
//                                   CustomButton(
//                                     text: 'Post Ride',
//                                     onPressed: _postRide,
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           if (_isPosting)
//             Center(
//               child: Container(
//                 color: Colors.black.withOpacity(0.5),
//                 child: const Center(
//                   child: CircularProgressIndicator(
//                     color: Colors.white,
//                     strokeWidth: 4.0,
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }