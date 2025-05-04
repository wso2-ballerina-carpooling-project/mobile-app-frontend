import 'package:flutter/material.dart';
// Reusable styled button widget

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color textColor;
  final double height;
  final double width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.height = 50,
    this.width = 150,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: width,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: textColor, fontSize: 16)),
      ),
    );
  }
}

// Main widget representing the "My Route" screen
class MyRoutePage extends StatelessWidget {
  const MyRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7), // Light grey background
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1033), // Deep navy bar
        title: const Text("My Route", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        elevation: 0, // Flat app bar
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16), // Page margin
            padding: const EdgeInsets.all(20), // Inner padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                // Light drop shadow
                BoxShadow(
                  // ignore: deprecated_member_use
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Each row represents a stop or point in the route
                _buildRouteRow(
                  time: "07:00",
                  name: "Moratuwa",
                  location: "Bandaranayake Road, Katubedda",
                  dotColor: Colors.green, // Green indicates start/end
                  showIcons: false,
                ),
                _buildGap("31 minute(s)"),
                _buildRouteRow(
                  time: "07:31",
                  name: "John Wick",
                  location: "Bandaranayake Road, Angulana",
                  dotColor: Colors.orange, // Orange indicates a pickup/drop
                ),
                _buildGap("39 minute(s)"),
                _buildRouteRow(
                  time: "08:10",
                  name: "John Wick",
                  location: "Bandaranayake Road, Angulana",
                  dotColor: Colors.orange,
                ),
                _buildGap("20 minute(s)"),
                _buildRouteRow(
                  time: "08:30",
                  name: "WSO2",
                  location: "Bandaranayake Road",
                  dotColor: Colors.green,
                  showIcons: false,
                ),
                const SizedBox(height: 30),
                // Action buttons at the bottom: Cancel and Start
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    CustomButton(
                      text: "Cancel",
                      onPressed: () {},
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                      height: 45,
                      width: 120,
                    ),
                    CustomButton(
                      text: "Start",
                      onPressed: () {},
                      backgroundColor: Colors.green,
                      height: 45,
                      width: 120,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget to show time difference between two route rows
  Widget _buildGap(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  // Widget for each route entry in the vertical timeline
  Widget _buildRouteRow({
    required String time,
    required String name,
    required String location,
    required Color dotColor,
    bool showIcons = true,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and vertical line
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 4),
            Container(width: 2, height: 40, color: Colors.grey.shade300),
          ],
        ),
        const SizedBox(width: 12),
        // Time, Name, and Address information
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                location,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
        // Optional Call and Message icons for passengers
        if (showIcons)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.call, size: 20),
                onPressed: () {}, // Placeholder for calling functionality
              ),
              IconButton(
                icon: const Icon(Icons.message, size: 20),
                onPressed: () {}, // Placeholder for messaging
              ),
            ],
          ),
      ],
    );
  }
}
