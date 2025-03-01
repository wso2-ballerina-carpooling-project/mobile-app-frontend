import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';

void main() {
  runApp(MyCarpoolApp());
}

class MyCarpoolApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: routes,
    );
  }
}
