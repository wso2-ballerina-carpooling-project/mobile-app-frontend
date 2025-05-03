import 'package:flutter/material.dart';
import 'views/ride_cancellation.dart'; // Import the RideCancellationPage

void main() {
  runApp(const RideCancellationApp());
}

class RideCancellationApp extends StatelessWidget {
  const RideCancellationApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ride Cancellation',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home:
          const RideCancellationPage(), // Set RideCancellationPage as the home page
    );
  }
}
