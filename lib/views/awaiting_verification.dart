import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/custom_button_secound.dart';

class AwaitingVerificationScreen extends StatelessWidget {
  const AwaitingVerificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151B3A), // Dark navy background color
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // This will push the content to the center
              const Spacer(flex: 2),
              
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  const Text(
                    "Awaiting Verification",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Thank you message
                  const Text(
                    "Thank you for registering.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Verification message
                  SizedBox(
                    width: 250,
                    child: Text(
                      "Your employee account is currently being verified by the WSO2 admin team.You'll receive an email once your access is activated.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  
                ],
              ),
              
              
              const Spacer(flex: 3),
              
              // Back to Login button
              
              CustomButtonSecoundary(
                text: "Back to Login",
                backgroundColor: btnColor,
                textColor: textColor,
                hasBorder: false,
                onPressed: () {
                 Navigator.of(context).pushReplacementNamed('/login');
                },
          
              ),
            ],
          ),
        ),
      ),
    );
  }
}