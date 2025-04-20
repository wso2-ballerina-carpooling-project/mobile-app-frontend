import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/map_sample.dart';
import 'package:mobile_frontend/views/passenger_registration.dart';
import 'package:mobile_frontend/views/signup_page.dart';
import '../views/loading_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoadingPage(),
  '/login': (context) => MapSample(),
  '/signup': (context) => SignupPage(),
  '/passengerRegistration': (context) => PassengerRegistration(),

};
