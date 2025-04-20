import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black, // Top half - black
              Colors.black, // Keeps it black till 50%
              Color(0xFF666666), // gray
            ],
            stops: [0.0, 0.5, 1.0], 
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
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'P',
                            style: TextStyle(color: Colors.orange),
                          ),
                          TextSpan(
                            text: 'oo',
                            style: TextStyle(color: Colors.white),
                          ),
                          TextSpan(
                            text: 'l',
                            style: TextStyle(color: Colors.blue),
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
                    Navigator.pushNamed(context, '/login');
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Get Started",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: MediaQuery.of(context).size.width * 0.2),
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.blue,
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
