import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/login_page.dart';
import 'package:mobile_frontend/views/map_sample.dart';
import 'package:mobile_frontend/views/registration.dart';
import '../views/loading_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoadingPage(),
  '/login': (context) => LoginPage(),
  '/signup': (context) => SignUpPage(),
  '/home': (context) => MapSample(),

};
