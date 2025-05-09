
// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/activities_page.dart';
import 'package:mobile_frontend/views/awaiting_verification.dart';
import 'package:mobile_frontend/views/driver/ride_start_screen.dart';
import 'package:mobile_frontend/views/driver_details.dart';
import 'package:mobile_frontend/views/login_page.dart';
import 'package:mobile_frontend/views/main_navigation.dart'; // Import the new file
import 'package:mobile_frontend/views/passenger/passenger_profile.dart';
import 'package:mobile_frontend/views/phone_update.dart';
import 'package:mobile_frontend/views/notification_page.dart';
import 'package:mobile_frontend/views/role_selection_screen.dart';
import 'package:mobile_frontend/views/signup_page.dart';
import 'package:mobile_frontend/views/passenger/passenger_ride_tracking.dart';
import '../views/loading_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) =>PassengerRideTracking(),
  '/login': (context) => PassengerProfile(),
  '/signup': (context) => SignUpScreen(),
  '/role': (context) => RoleSelectionScreen(),
  '/driverdetails': (context) => DriverDetailsScreen(),
  '/waiting': (context) => AwaitingVerificationScreen(),
  '/rideStart': (context) => RideStartScreen(),
  '/phoneEdit': (context) => PhoneInputPage(),
  // Add the main navigation route
  // '/main': (context) => MainNavigation(),
};