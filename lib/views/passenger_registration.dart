import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';

class PassengerRegistration extends StatelessWidget {
  const PassengerRegistration({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150), // Adjust height
        child: AppBar(
          automaticallyImplyLeading: false, // Removes default back button
          backgroundColor: primaryColor, // Dark Blue Background
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
                      style: TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold),
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
      body: const Center(child: Text("Passenger Registration Form",style: TextStyle(color: Colors.black),)),
    );
  }
}
