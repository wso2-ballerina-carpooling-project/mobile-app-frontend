import 'package:flutter/material.dart';
import 'package:mobile_frontend/widgets/custom_button_secound.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: Your "Back to Login" button with white background
            CustomButtonSecoundary(
              text: "Back to Login",
              backgroundColor: Colors.white,
              textColor: Colors.black,
              hasBorder: true,
              borderColor: Colors.blue,
              borderWidth: 1.5,
              onPressed: () {
                Navigator.pop(context);
              },
              width: 300,
            ),
            
            SizedBox(height: 20),
            
            // Example 2: A blue button with white text
            CustomButtonSecoundary(
              text: "Continue",
              backgroundColor: Colors.blue,
              textColor: Colors.white,
              onPressed: () {
                // Your action here
              },
            ),
            
            SizedBox(height: 20),
            
            // Example 3: A red button with custom dimensions
            CustomButtonSecoundary(
              text: "Delete Account",
              backgroundColor: Colors.red,
              textColor: Colors.white,
              width: 200,
              height: 45,
              onPressed: () {
                // Your action here
              },
            ),
          ],
        ),
      ),
    );
  }
}