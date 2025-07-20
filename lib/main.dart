import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_frontend/services/local_notification.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_frontend/config/routes.dart';
import 'package:mobile_frontend/config/theme.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('🔕 Handling background message: ${message.messageId}');
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
  LocalNotificationsService notificationsService = LocalNotificationsService();
  await notificationsService.init();

  RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  runApp(const MyCarpoolApp());
}

Future<void> requestLocationPermission() async {
  var status = await Permission.location.status;

  if (status.isDenied || status.isRestricted) {
    status = await Permission.location.request();
  }

  if (status.isPermanentlyDenied) {
    await openAppSettings();
  }
}

Future<void> setupFirebaseMessaging() async {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

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
  if (token is String) {
    await prefs.setString('fcm', token);
  }
  print('Device FCM Token: $token');

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('🔔 Received message in foreground: ${message.notification?.title}');
    print('🔔 Message body: ${message.notification?.body}');
  });
 FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('User tapped on notification: ${message.data}');
    if (message.data['callId'] != null) {
      await _navigateToCallScreen(message.data);
    }
  });
}

Future<void> _navigateToCallScreen(Map<String, dynamic> data) async {
  // Retry navigation until navigator is available
  const maxRetries = 10;
  var retries = 0;
  while (retries < maxRetries) {
    final navigator = navigatorKey.currentState;
    if (navigator != null) {
      navigator.pushNamed(
        '/call',
        arguments: {
          'callId': data['callId'],
          'channelName': data['channelName'],
          'callerName': data['callerName'] ?? data['callerId'] ?? 'Unknown',
        },
      );
      print('Navigation to CallScreen successful');
      return;
    }
    print('Navigator not available, retrying (${retries + 1}/$maxRetries)...');
    await Future.delayed(const Duration(milliseconds: 500));
    retries++;
  }
  print('Failed to navigate: Navigator not available after $maxRetries retries');
}


class MyCarpoolApp extends StatelessWidget {
   final RemoteMessage? initialMessage;
  const MyCarpoolApp({super.key,this.initialMessage});

  @override
  Widget build(BuildContext context) {
     if (initialMessage != null && initialMessage!.data['callId'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print('App launched from notification: ${initialMessage!.data}');
        await _navigateToCallScreen(initialMessage!.data);
      });
    }
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      navigatorKey: navigatorKey, 
      initialRoute: '/',
      routes: routes,
    );
  }
}