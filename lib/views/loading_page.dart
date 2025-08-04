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

class _LoadingPageState extends State<LoadingPage> with TickerProviderStateMixin {
  final _storage = FlutterSecureStorage();
  bool _isCheckingToken = true;
  bool _showButton = true;
  bool _showCarOnButton = false;
  bool _showRoad = false;

  late AnimationController _animationController;
  late AnimationController _roadAnimationController;
  late AnimationController _buttonAnimationController;
  late Animation<double> _carAnimation;
  late Animation<double> _roadAnimation;
  late Animation<double> _carBounceAnimation;
  late Animation<double> _buttonSlideAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _roadAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _buttonAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _carAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController, 
        curve: const Interval(0.2, 1.0, curve: Curves.easeInOut)
      ),
    );

    // Road animation that starts before car animation
    _roadAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _roadAnimationController, 
        curve: Curves.easeInOut
      ),
    );

    // Subtle bounce animation for the car
    _carBounceAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Button slide out animation
    _buttonSlideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: Curves.easeInQuart,
      ),
    );

    // Button fade out animation
    _buttonFadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _buttonAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _checkTokenAndNavigate();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _roadAnimationController.dispose();
    _buttonAnimationController.dispose();
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
    // Start button hide animation
    _buttonAnimationController.forward().then((_) {
      setState(() {
        _showButton = false;
        _showCarOnButton = true;
        _showRoad = true;
      });

      // Start road animation first
      _roadAnimationController.forward();
      
      // Start car animation with slight delay
      Future.delayed(const Duration(milliseconds: 200), () {
        _animationController.forward(from: 0.0).then((_) {
          // Navigate after animation completes
          Future.delayed(const Duration(milliseconds: 300), () {
            Navigator.pushReplacementNamed(context, '/login');
          });
        });
      });
    });
  }

  Widget _buildRoadLines() {
    return AnimatedBuilder(
      animation: _roadAnimation,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          height: 4,
          child: CustomPaint(
            painter: RoadLinePainter(_roadAnimation.value),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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

              // Road and Button/Car Animation Area
              Container(
                height: 140,
                child: Stack(
                  children: [
                    // Road Background
                    if (_showRoad)
                      Positioned(
                        top: 30,
                        left: 0,
                        right: 0,
                        child: AnimatedOpacity(
                          opacity: _showRoad ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            height: 80,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey[700]!,
                                  Colors.grey[800]!,
                                  Colors.grey[900]!,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildRoadLines(),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Get Started Button
                    if (_showButton)
                      Positioned(
                        top: 25,
                        left: 0,
                        child: AnimatedBuilder(
                          animation: _buttonAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(-_buttonSlideAnimation.value * 400, 0),
                              child: Opacity(
                                opacity: _buttonFadeAnimation.value,
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
                                    elevation: 8,
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
                                      SizedBox(width: screenWidth * 0.2),
                                      const CircleAvatar(
                                        radius: 24,
                                        backgroundColor: mainButtonColor,
                                        child: Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                    // Animated Car
                    if (_showCarOnButton)
                      AnimatedBuilder(
                        animation: _carAnimation,
                        builder: (context, child) {
                          return Positioned(
                            top: 25 + (5 * (1 - _carBounceAnimation.value)), // Slight bounce effect
                            left: _carAnimation.value * (screenWidth + 100) - 50,
                            child: Transform.scale(
                              scale: 1.0 + (0.1 * _carBounceAnimation.value), // Slight scale effect
                              child: Container(
                                height: 90,
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'assets/anima.webp',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                  ],
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

// Custom painter for animated road lines
class RoadLinePainter extends CustomPainter {
  final double animationValue;
  
  RoadLinePainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dashWidth = 30.0;
    final dashSpace = 20.0;
    final totalDashWidth = dashWidth + dashSpace;
    
    // Calculate offset based on animation
    final offset = animationValue * totalDashWidth;
    
    double startX = -offset;
    while (startX < size.width) {
      if (startX + dashWidth > 0) {
        canvas.drawLine(
          Offset(startX.clamp(0, size.width), size.height / 2),
          Offset((startX + dashWidth).clamp(0, size.width), size.height / 2),
          paint,
        );
      }
      startX += totalDashWidth;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is RoadLinePainter && 
           oldDelegate.animationValue != animationValue;
  }
}