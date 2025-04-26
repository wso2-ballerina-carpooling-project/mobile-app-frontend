import 'package:flutter/material.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'views/account_change_confirmation.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyCarpoolApp());
}

class MyCarpoolApp extends StatelessWidget {
  const MyCarpoolApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create a new map without the '/' route
    final modifiedRoutes = Map<String, WidgetBuilder>.from(routes);
    modifiedRoutes.remove('/'); // Remove default route if it exists
    
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: AccountChangeSuccessScreen(), // Keep this
      routes: modifiedRoutes, // Use modified routes
    );
  }
}