import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class PhoneInputPage extends StatefulWidget {
  const PhoneInputPage({Key? key}) : super(key: key);

  @override
  State<PhoneInputPage> createState() => _PhoneInputPageState();
}

class _PhoneInputPageState extends State<PhoneInputPage> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill the phone number
    _phoneController.text = '071 929 7961';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: primaryColor, // Dark navy background color
        child: SafeArea(
          child: Column(
            children: [
              // App bar with back button and centered title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: primaryColor, // Dark navy color
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 0,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context); // Handle back button press
                        },
                      ),
                    ),
                    const Text(
                      'Phone',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // White content area
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: const BoxDecoration(
                    color: bgcolor,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(24.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Phone input field using CustomInputField
                      CustomInputField(
                        label: 'Phone',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        hintText: 'Enter phone number',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a phone number';
                          }
                          return null;
                        },
                      ),

                      // Spacer to push the button to the bottom
                      const Spacer(),

                      // Save button using CustomButton
                      CustomButton(
                        text: 'Save',
                        backgroundColor: const Color(0xFF4CAF50), // Green color
                        textColor: Colors.white,
                        height: 50.0,
                        width: double.infinity,
                        onPressed: () {
                          // Handle save button press
                          final phoneNumber = _phoneController.text;
                          if (phoneNumber.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a phone number')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}