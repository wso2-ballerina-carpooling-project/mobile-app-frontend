import 'package:flutter/material.dart';
import '../config/constant.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class LoginPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(appLogo, height: 100),
            SizedBox(height: 20),
            Text("Welcome back!", style: TextStyle(color: Colors.white, fontSize: 18)),
            CustomInputField(hint: "Username"),
            CustomInputField(hint: "Password", obscureText: true),
            SizedBox(height: 20),
            CustomButton(text: "Login", onPressed: () {
              Navigator.pushNamed(context, '/signup');
            }),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/signup'),
              child: Text("Don't have an account? Register", style: TextStyle(color: Colors.white)),
            ),
            SizedBox(height: 30),
            Image.asset(companyLogo, height: 50),
          ],
        ),
      ),
    );
  }
}
