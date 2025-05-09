
// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/awaiting_verification.dart';
import 'package:mobile_frontend/views/common/name_update.dart';
import 'package:mobile_frontend/views/driver/ride_start_screen.dart';
import 'package:mobile_frontend/views/driver_details.dart';
import 'package:mobile_frontend/views/login_page.dart';
// Import the new file
import 'package:mobile_frontend/views/common/phone_update.dart';
import 'package:mobile_frontend/views/role_selection_screen.dart';
import 'package:mobile_frontend/views/signup_page.dart';
import '../views/loading_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoadingPage(),
  '/login': (context) => LoginPage(),
  '/signup': (context) => SignUpScreen(),
  '/role': (context) => RoleSelectionScreen(),
  '/driverdetails': (context) => DriverDetailsScreen(),
  '/waiting': (context) => AwaitingVerificationScreen(),
  '/rideStart': (context) => RideStartScreen(),
  '/phoneEdit': (context) => PhoneUpdate(),
  '/nameEdit' : (context) => NameUpdateScreen(),
  // Add the main navigation route
  // '/main': (context) => MainNavigation(),
};