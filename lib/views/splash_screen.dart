// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:mobile_frontend/services/auth_service.dart';
// import 'package:mobile_frontend/config/constant.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     // Delay slightly to ensure the provider is properly initialized
//     Future.delayed(const Duration(milliseconds: 100), () {
//       _checkLoginStatus();
//     });
//   }

//   Future<void> _checkLoginStatus() async {
//     // Check if user is already logged in
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final isLoggedIn = await authProvider.checkLoginStatus();

//     // Navigate to appropriate screen
//     if (mounted) {
//       if (isLoggedIn) {
//         Navigator.of(context).pushReplacementNamed('/home');
//       } else {
//         Navigator.of(context).pushReplacementNamed('/login');
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: primaryColor,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Image.asset(
//               appLogo,
//               width: 150,
//               height: 150,
//             ),
//             const SizedBox(height: 24),
//             const CircularProgressIndicator(
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }