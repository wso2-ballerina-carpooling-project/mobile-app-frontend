import 'package:flutter/material.dart';
import '../config/constant.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/login');
    });

    return Scaffold(
      backgroundColor: primaryColor,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Spacer(),
          Center(child: Image.asset(appLogo, height: 150)),
          Spacer(),
          Column(
            children: [
              Text(
                "Powered by",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              SizedBox(height: 5),
              Image.asset(companyLogo, height: 50),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}
