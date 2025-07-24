import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';
import 'package:mobile_frontend/services/auth_services.dart';

class DriverDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DriverDetailsScreen({super.key, required this.userData});

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehicleRegistrationController = TextEditingController();
  String? _vehicleTypeValue;
  String? _vehicleBrandValue;
  int _numberOfSeats = 2;
  bool _isLoading = false; // Added to track loading state

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _vehicleRegistrationController.dispose();
    super.dispose();
  }

  void _validateAndRegister() async {
    if (_vehicleTypeValue == null ||
        _vehicleBrandValue == null ||
        _vehicleModelController.text.isEmpty ||
        _vehicleRegistrationController.text.isEmpty ||
        _numberOfSeats < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all driver details')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Set loading state to true before API call
    });

    final vehicleDetails = {
      'vehicleType': _vehicleTypeValue,
      'vehicleBrand': _vehicleBrandValue,
      'vehicleModel': _vehicleModelController.text,
      'vehicleRegistrationNumber': _vehicleRegistrationController.text,
      'seatingCapacity': _numberOfSeats,
    };

    final registrationData = {
      ...widget.userData,
      'role': 'driver',
      'vehicleDetails': vehicleDetails,
    };

    try {
      final response = await ApiService.registerUser(registrationData);
      if (response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/waiting');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Reset loading state after API call completes
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          Positioned(
            top: screenSize.height * 0.07,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          Positioned(
            top: screenSize.height * 0.05,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 100,
                height: 80,
                child: Image.asset(
                  appLogo,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: bgcolor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Complete Your Registration",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.normal,
                            color: Colors.black87,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      CustomDropdownField(
                        label: 'Vehicle Type',
                        options: ['Mini', 'Flex', 'Suv', 'Van'],
                        value: _vehicleTypeValue,
                        hintText: 'Select vehicle type',
                        onChanged: (value) {
                          setState(() {
                            _vehicleTypeValue = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomDropdownField(
                        label: 'Vehicle Brand',
                        options: ['Toyota', 'Honda', 'Nissan', 'Ford', 'BMW', 'Mercedes', 'Audi'],
                        value: _vehicleBrandValue,
                        hintText: 'Select vehicle brand',
                        onChanged: (value) {
                          setState(() {
                            _vehicleBrandValue = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Vehicle Model',
                        controller: _vehicleModelController,
                        hintText: 'Civic',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Vehicle Registration Number',
                        controller: _vehicleRegistrationController,
                        hintText: 'CBL-8090',
                        keyboardType: TextInputType.text,
                      ),
                      const SizedBox(height: 20),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No. of seats available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 60,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _numberOfSeats.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (_numberOfSeats < 10) {
                                            _numberOfSeats++;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 22.5,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(color: Colors.grey.shade300),
                                            bottom: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        child: const Icon(Icons.add, size: 16),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (_numberOfSeats > 1) {
                                            _numberOfSeats--;
                                          }
                                        });
                                      },
                                      child: Container(
                                        width: 28,
                                        height: 22.5,
                                        decoration: BoxDecoration(
                                          border: Border(
                                            left: BorderSide(color: Colors.grey.shade300),
                                          ),
                                        ),
                                        child: const Icon(Icons.remove, size: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      _isLoading
                          ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                          : CustomButton(
                              text: 'Complete Registration',
                              onPressed: _validateAndRegister,
                            ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}