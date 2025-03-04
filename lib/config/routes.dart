import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/signup_page.dart';
import '../views/loading_page.dart';
import '../views/login_page.dart';

final Map<String, WidgetBuilder> routes = {
  '/': (context) => LoadingPage(),
  '/login': (context) => LoginPage(),
  '/signup': (context) => SignupPage(),
};
