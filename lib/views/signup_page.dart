import 'package:flutter/material.dart';
import '../config/constant.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(height: 150),
              Center(
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text("Logo", style: TextStyle(color: Colors.black, fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.45,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Register as...",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 200,
                          child: CustomButton(
                            text: "Passenger",
                            onPressed: () {
                              Navigator.pushNamed(context, '/');
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: SizedBox(
                          width: 200,
                          child: CustomButton(
                            text: "Driver",
                            onPressed: () {
                              Navigator.pushNamed(context, '/');
                            },
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/signup'),
                          child: Text(
                            "have an account? Login",
                            style: TextStyle(color: primaryColor, fontSize: 14),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.only(bottom: 10),
                  child: Center(
                    child: Image.asset(companyLogo, height: 30),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}