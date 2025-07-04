
// lib/config/routes.dart
import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/auth/awaiting_verification.dart';
import 'package:mobile_frontend/views/common/name_update.dart';
import 'package:mobile_frontend/views/common/vehicle_update.dart';
import 'package:mobile_frontend/views/driver/ride_start_screen.dart';
import 'package:mobile_frontend/views/auth/driver_details.dart';
import 'package:mobile_frontend/views/auth/login_page.dart';
// Import the new file
import 'package:mobile_frontend/views/common/phone_update.dart';
import 'package:mobile_frontend/views/auth/role_selection_screen.dart';
import 'package:mobile_frontend/views/auth/signup_page.dart';
import '../views/loading_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoadingPage(),
  '/login': (context) => LoginPage(),
  '/signup': (context) => SignUpScreen(),
  '/role': (context) => RoleSelectionScreen(userData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,),
  '/driver-details': (context) => DriverDetailsScreen(userData: ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>,),
  '/waiting': (context) => AwaitingVerificationScreen(),
  '/rideStart': (context) => RideStartScreen(),
  '/phoneEdit': (context) => PhoneUpdate(),
  '/nameEdit' : (context) => NameUpdateScreen(),
  '/vehicleEdit' : (context) => VehicleUpdate(),
  // Add the main navigation route
  // '/main': (context) => MainNavigation(),
};