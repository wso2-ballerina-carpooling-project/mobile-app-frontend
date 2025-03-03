import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/passenger_registration.dart';
//import '../views/loading_page.dart';
import '../views/login_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => PassengerRegistration(),
  '/login': (context) => LoginPage(),
  
};
