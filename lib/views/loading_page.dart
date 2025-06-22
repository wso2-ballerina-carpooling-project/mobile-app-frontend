import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/views/main_navigation.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  final _storage = FlutterSecureStorage();
  bool _isCheckingToken = true;

  @override
  void initState() {
    super.initState();
    _checkTokenAndNavigate();
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      // Retrieve token from secure storage
      String? token = await _storage.read(key: 'jwt_token');

      if (token == null) {
        // No token, show Get Started UI
        setState(() {
          _isCheckingToken = false;
        });
        return;
      }

      // Decode and validate token
      Map<String, dynamic> payload;
      try {
        payload = Jwt.parseJwt(token);
      } catch (e) {
        // Invalid token format, clear storage and show Get Started UI
        await _storage.delete(key: 'jwt_token');
        setState(() {
          _isCheckingToken = false;
        });
        return;
      }

      // Check token expiry
      if (Jwt.isExpired(token)) {
        // Token expired, clear storage and show Get Started UI
        await _storage.delete(key: 'jwt_token');
        setState(() {
          _isCheckingToken = false;
        });
        return;
      }

      // Extract user details
      final userRole = payload['role'] ?? 'passenger';
      final userStatus = payload['status'] ?? 'unknown';

      // Navigate based on status
      if (userStatus == 'pending' && userRole != 'admin') {
        Navigator.pushReplacementNamed(context, '/waiting');
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainNavigation(
              userRole: userRole == 'driver' ? UserRole.driver : UserRole.passenger,
            ),
          ),
        );
      }
    } catch (e) {
      // Any error, clear storage and show Get Started UI
      print('Error checking token: $e');
      await _storage.delete(key: 'jwt_token');
      setState(() {
        _isCheckingToken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    // Show loading indicator while checking token
    if (_isCheckingToken) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show Get Started UI if no valid token
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromRGBO(10, 14, 42, 1),
              primaryColorWithOpacity,
              Color.fromARGB(255, 86, 86, 86),
              Color.fromARGB(255, 116, 116, 116),
            ],
            stops: [0.0, 0.5, 0.75, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Centered Brand Name and Subtitle
              Center(
                child: Column(
                  children: [
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Car ',
                            style: TextStyle(color: textColor),
                          ),
                          TextSpan(
                            text: 'P',
                            style: TextStyle(color: companyColor),
                          ),
                          TextSpan(
                            text: 'oo',
                            style: TextStyle(color: textColor),
                          ),
                          TextSpan(
                            text: 'l',
                            style: TextStyle(color: mainButtonColor),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 0),
                    const Text(
                      'Share your ride. Save the planet\none trip at a time',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 0),
              // Car image taking 50% of screen height
              SizedBox(
                height: screenHeight * 0.5,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset('assets/car.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 0),
              // Get Started Button
              Align(
                alignment: Alignment.centerLeft,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    minimumSize: const Size(0, 90),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 18,
                    ),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(50),
                        bottomRight: Radius.circular(50),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Get Started",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.2),
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: mainButtonColor,
                        child: Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}