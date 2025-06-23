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

class _LoadingPageState extends State<LoadingPage> with SingleTickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  bool _isCheckingToken = true;
  bool _showButton = true;
  bool _showCarOnButton = false;

  late AnimationController _animationController;
  late Animation<double> _carAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _carAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _checkTokenAndNavigate();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkTokenAndNavigate() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');

      if (token == null) {
        setState(() {
          _isCheckingToken = false;
        });
        return;
      }

      Map<String, dynamic> payload;
      try {
        payload = Jwt.parseJwt(token);
      } catch (e) {
        await _storage.delete(key: 'jwt_token');
        setState(() {
          _isCheckingToken = false;
        });
        return;
      }

      if (Jwt.isExpired(token)) {
        await _storage.delete(key: 'jwt_token');
        setState(() {
          _isCheckingToken = false;
        });
        return;
      }

      final userRole = payload['role'] ?? 'passenger';
      final userStatus = payload['status'] ?? 'unknown';

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
      print('Error checking token: $e');
      await _storage.delete(key: 'jwt_token');
      setState(() {
        _isCheckingToken = false;
      });
    }
  }

  void _startCarAnimationAndNavigate() {
    setState(() {
      _showButton = false;
      _showCarOnButton = true;
    });

    _animationController.forward(from: 0.0).then((_) {
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isCheckingToken) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              // App Name & Subtitle
              Column(
                children: [
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
                      children: const [
                        TextSpan(text: 'Car ', style: TextStyle(color: textColor)),
                        TextSpan(text: 'P', style: TextStyle(color: companyColor)),
                        TextSpan(text: 'oo', style: TextStyle(color: textColor)),
                        TextSpan(text: 'l', style: TextStyle(color: mainButtonColor)),
                      ],
                    ),
                  ),
                  const Text(
                    'Share your ride. Save the planet\none trip at a time',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Hero car image
              SizedBox(
                height: screenHeight * 0.4,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Image.asset('assets/car.png', fit: BoxFit.contain),
                ),
              ),

              const SizedBox(height: 20),

              // Get Started Button / Animated Car
              Stack(
                children: [
                  if (_showButton)
                    AnimatedOpacity(
                      opacity: _showButton ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 500),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(0, 90),
                            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 18),
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(50),
                                bottomRight: Radius.circular(50),
                              ),
                            ),
                          ),
                          onPressed: _startCarAnimationAndNavigate,
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
                                child: Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  if (_showCarOnButton)
                    AnimatedBuilder(
                      animation: _carAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(_carAnimation.value * MediaQuery.of(context).size.width, 0),
                          child: child,
                        );
                      },
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 90,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 0),
                            child: Image.asset('assets/anima.webp'),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
