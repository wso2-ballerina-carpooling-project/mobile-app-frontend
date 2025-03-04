import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';

class PassengerRegistration extends StatefulWidget {
  const PassengerRegistration({super.key});

  @override
  _PassengerRegistrationState createState() => _PassengerRegistrationState();
}

class _PassengerRegistrationState extends State<PassengerRegistration> {
  bool _isChecked = false; // Checkbox state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: primaryColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(10),
              bottomRight: Radius.circular(10),
            ),
          ),
          flexibleSpace: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Welcome!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 14),
                    Text(
                      "Register as Passenger",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () {
                      // Close button action
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: const Color(0xFFF5F5F5),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const CustomInputField(label: "Name", hint: "John Deo"),
                  const SizedBox(height: 15),
                  const CustomInputField(label: "Phone", hint: "+94 11 222 2222"),
                  const SizedBox(height: 15),
                  const CustomInputField(label: "Company Email", hint: "johndeo@wso2.lk"),
                  const SizedBox(height: 15),
                  const CustomInputField(label: "Password", hint: "***********************"),
                  const SizedBox(height: 15),
                  const CustomInputField(label: "Confirm Password", hint: "***********************"),
                  const SizedBox(height: 10),
                  
                  // Checkbox Row
                  Row(
                    children: [
                      Checkbox(
                        value: _isChecked,
                        onChanged: (bool? value) {
                          setState(() {
                            _isChecked = value!;
                          });
                        },
                        activeColor: primaryColor, // Checkbox color
                      ),
                      const Expanded(
                        child: Text(
                          "I agree to the terms and conditions",
                          style: TextStyle(fontSize: 14, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Register Button
                  ElevatedButton(
                    onPressed: _isChecked ? () {
                      // Handle registration action
                    } : null, // Disable button if not checked
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: const Text(
                      "Register",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const Spacer(), // Pushes the logo to the bottom

                  // Company Logo at Bottom
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(companyLogo, height: 20),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
