// // main.dart
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'config/routes.dart';
// import 'config/theme.dart';

// void main() {
//   WidgetsFlutterBinding.ensureInitialized();
//   SystemChrome.setSystemUIOverlayStyle(
//     const SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent,
//       statusBarIconBrightness: Brightness.dark,
//     ),
//   );
//   runApp(const MyCarpoolApp());
// }

// class MyCarpoolApp extends StatelessWidget {
//   const MyCarpoolApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Carpool App',
//       debugShowCheckedModeBanner: false,
//       theme: appTheme,
//       initialRoute: '/',
//       routes: routes,
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/ride_listing_screen.dart';
 // <-- Import the page I gave you

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ride Booking App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const RideSelectionPage(), // <-- Set your Ride Selection Page as home
    );
  }
}
