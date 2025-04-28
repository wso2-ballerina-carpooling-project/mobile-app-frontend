import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';

class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({Key? key}) : super(key: key);

  @override
  State<DriverDetailsScreen> createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  // Controllers
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Separate variables for each dropdown
  String? _vehicleTypeValue;
  String? _vehicleBrandValue;
  
  // Counter for number of seats
  int _numberOfSeats = 2;
  
  
  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          // Back button (top left)
          Positioned(
            top: screenSize.height * 0.07,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Center logo
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
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                ),
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

                      // Form fields with separate dropdown variables
                      CustomDropdownField(
                        label: 'Vehicle Type',
                        options: ['Sedan', 'SUV', 'Hatchback', 'Van', 'Truck'],
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
                        controller: _emailController,
                        hintText: 'Civic',
                        keyboardType: TextInputType.text,
                      ),

                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Vehicle Registration Number',
                        controller: _phoneController,
                        hintText: 'CBL-8090',
                        keyboardType: TextInputType.text,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Number of seats counter
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
                                // Number display
                                Container(
                                  width: 60,
                                  height: 45,
                                  alignment: Alignment.center,
                                  child: Text(
                                    _numberOfSeats.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black
                                    ),
                                  ),
                                ),
                                // Plus and minus buttons column
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Increase button
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
                                    // Decrease button
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

                      CustomButton(
                        text: 'Complete Registration',
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/waiting');
                        },
                      ),
                      
                      // Add extra space at the bottom
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