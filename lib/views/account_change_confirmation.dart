import 'package:flutter/material.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';

class AccountChangeSuccessScreen extends StatelessWidget {
  const AccountChangeSuccessScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003366), // Dark blue background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Success icon
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF4CAF50), // Green color
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              const SizedBox(height: 30),

              // Success message
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Your account change successfully',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Back to login button using custom button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: CustomButton(
                  text: 'Back to Login',
                  backgroundColor: const Color(0xFF4CAF50), // Green button
                  textColor: Colors.white,
                  //borderRadius: 8.0,
                  onPressed: () {
                    // Navigate back to login screen
                    Navigator.of(context).pushReplacementNamed('/login');
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}