// import 'package:flutter/material.dart';
// import 'config/routes.dart';
// import 'config/theme.dart';

// void main() {
//   runApp(MyCarpoolApp());
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
import 'package:mobile_frontend/views/ride_post_confirmation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false, // Hides the debug banner
      theme: ThemeData(primarySwatch: Colors.blue),
      home:
          const RidePostConfirmationPage(), // Set RidePostConfirmationPage as the home page
    );
  }
}
