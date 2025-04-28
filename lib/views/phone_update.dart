import 'package:flutter/material.dart';
import '../widgets/custom_button.dart'; // Import the CustomButton widget
import '../widgets/custom_input_field.dart'; // Import the CustomInputField widget

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Phone Input',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const PhoneInputPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
        color: const Color(0xFF003366), // Dark navy background color
        child: SafeArea(
          child: Column(
            children: [
              // App bar with back button and title
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: const Color(0xFF003366), // Dark navy color
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context); // Handle back button press
                      },
                    ),
                    const SizedBox(width: 8.0),
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
                    color: Colors.white,
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
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Phone number saved: $phoneNumber')),
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