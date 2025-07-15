import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'config/routes.dart';
import 'config/theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔕 Handling background message: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await requestLocationPermission();
  await Firebase.initializeApp();
  await setupFirebaseMessaging(); 

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

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // Request permissions (important for iOS and Android 13+)
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    print('User granted permission');
  } else {
    print('User declined or has not accepted permission');
  }

  String? token = await messaging.getToken();
  final prefs = await SharedPreferences.getInstance();
  if(token is String){
    await prefs.setString('fcm', token);
  }
  print('Device FCM Token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔔 Received message in foreground: ${message.notification?.title}');
    print('🔔 Message body: ${message.notification?.body}');
  });

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    print('User tapped on notification');
    // Navigate to a screen, show dialog, etc.
  });
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