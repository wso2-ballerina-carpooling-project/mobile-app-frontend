import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'config/routes.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Request location permission before launching app
  await requestLocationPermission();

  runApp(const MyCarpoolApp());
}

Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;

  if (status.isDenied || status.isRestricted) {
    status = await Permission.location.request();
  }

  if (status.isPermanentlyDenied) {
    // Open app settings if user blocked it forever
    await openAppSettings();
  }

}

class MyCarpoolApp extends StatelessWidget {
  const MyCarpoolApp({super.key});

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
