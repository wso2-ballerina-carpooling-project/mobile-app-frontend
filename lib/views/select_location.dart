import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mobile_frontend/config/constant.dart';

class SelectLocation extends StatefulWidget {
  final LatLng? initialLocation;

  const SelectLocation({super.key, this.initialLocation});

  @override
  State<SelectLocation> createState() => _SelectLocationState();
}

class _SelectLocationState extends State<SelectLocation> {
  final Completer<GoogleMapController> _controller = Completer();
  late GoogleMapController mapController;

  LatLng? _selectedLocation;
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  String _selectedAddress = 'Unknown Location';
  
  // Timer for debouncing address updates
  Timer? _debounceTimer;
  
  // Store current camera position
  CameraPosition? _currentCameraPosition;

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation;
      _updateAddress(widget.initialLocation!);
    } else {
      _loadInitialLocation();
    }
  }

  Future<void> _loadInitialLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
        }
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      if (mounted) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });

        if (_controller.isCompleted) {
          final controller = await _controller.future;
          await controller.animateCamera(
            CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
          );
        }

        await _updateAddress(_selectedLocation!);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _updateAddress(LatLng location) async {
    if (!mounted) return;
    
    setState(() => _isLoadingAddress = true);
    
    try {
      // Add a small delay to ensure coordinates are stable
      await Future.delayed(const Duration(milliseconds: 500));
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
        localeIdentifier: 'en_US', // Specify locale for consistency
      );
      
      if (mounted && placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        
        // Build address more carefully
        String address = '';
        
        if (placemark.name != null && placemark.name!.isNotEmpty) {
          address += placemark.name!;
        }
        
        if (placemark.street != null && placemark.street!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.street!;
        }
        
        if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.subLocality!;
        }
        
        if (placemark.locality != null && placemark.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += placemark.locality!;
        }
        
        if (address.isEmpty) {
          address = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        }
        
        setState(() {
          _selectedAddress = address;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress = '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddress = false);
      }
    }
  }

  // Method to get exact map center coordinates with debounced address updates
  void _onCameraMove(CameraPosition position) {
    // Store the current camera position
    _currentCameraPosition = position;
    
    if (mounted) {
      setState(() {
        _selectedLocation = position.target;
      });
    }
  }

  void _onCameraIdle() async {
    if (!mounted || _currentCameraPosition == null) return;
    
    try {
      LatLng centerLocation = _currentCameraPosition!.target;

      // Cancel previous timer if it exists
      _debounceTimer?.cancel();
      
      // Start new timer for debounced address update
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        if (mounted) {
          _updateAddress(centerLocation);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting center location: $e')),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    
    setState(() => _isLoadingLocation = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      LatLng newLocation = LatLng(position.latitude, position.longitude);
      
      if (mounted) {
        setState(() {
          _selectedLocation = newLocation;
        });
        
        final controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newLatLngZoom(newLocation, 15),
        );
        
        await _updateAddress(newLocation);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initialPosition = _selectedLocation ?? const LatLng(6.89617, 79.85657);

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
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              _controller.complete(controller);
              
              // Set initial location if available
              if (_selectedLocation != null) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(_selectedLocation!, 15),
                  );
                });
              }
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: _onCameraIdle,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            // Add some styling
            mapType: MapType.normal,
            zoomControlsEnabled: false,
          ),
          
          // Center Pin with shadow
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 48,
            left: MediaQuery.of(context).size.width / 2 - 24,
            child: Column(
              children: [
                Container(
                  decoration: BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ).toBorder(),
                  child: const Icon(
                    Icons.location_pin, 
                    size: 48, 
                    color: mainButtonColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Location',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: mainButtonColor, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _isLoadingAddress
                            ? Row(
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Loading address...',
                                    style: TextStyle(color: Colors.grey, fontSize: 14),
                                  ),
                                ],
                              )
                            : Text(
                                _selectedAddress,
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                      ),
                    ],
                  ),
                  if (_selectedLocation != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                      'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _selectedLocation != null && !_isLoadingAddress
                        ? () => Navigator.pop(context, _selectedLocation)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedLocation != null && !_isLoadingAddress 
                          ? Colors.blue 
                          : Colors.grey,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Floating Button for current location
          Positioned(
            bottom: 210,
            right: 20,
            child: Container(
              decoration: BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ).toBorder(),
              child: FloatingActionButton(
                heroTag: 'current_location',
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                backgroundColor: Colors.white,
                foregroundColor: mainButtonColor,
                child: _isLoadingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: mainButtonColor,
                        ),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Extension to help with shadow decoration
extension ShadowExtension on BoxShadow {
  Decoration toBorder() {
    return BoxDecoration(
      // boxShadow: [this],
    );
  }
}