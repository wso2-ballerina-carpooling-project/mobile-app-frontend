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
import 'package:mobile_frontend/views/driver_details.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      debugShowCheckedModeBanner: false, // Optional: hides the debug banner
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DriverDetailsPage(), // 👈 Set this as the home page
    );
  }
}