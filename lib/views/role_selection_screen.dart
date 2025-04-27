import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: primaryColor, // Dark background color
      body: Stack(
        children: [
          // Back button (top left)
          Positioned(
            top: 50,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),

          // Center logo
          Positioned(
            top: screenSize.height * 0.20,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 140,
                height: 120,
                child: Image.asset(
                  appLogo, // Using the logo defined in constant.dart
                  fit: BoxFit.contain, // Keep image aspect ratio
                ),
              ),
            ),
          ),

          // White container at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.5, // Adjust the height here
            child: Container(
              decoration: const BoxDecoration(
                color: bgcolor, // Your white background color
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),

                    // Title "Choose Your Role"
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Choose Your Role",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                    const SizedBox(height: 70),

                    // Driver Button
                    CustomButton(
                      text: "Driver",
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                    ),
                    const SizedBox(height: 30),

                    // Passenger Button
                    CustomButton(
                      text: "Passenger",
                      onPressed: () {
                        Navigator.pushNamed(context, '/home');
                      },
                    ),
                    const Spacer(),

                    // Already have an account? Sign In
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                            fontFamily: 'Inter',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context)
                                .pushReplacementNamed('/login');
                          },
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              color: Color(0xFF5D5FEF),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
