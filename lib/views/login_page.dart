import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Logo section
            Expanded(
              flex: 2,
              child: Center(
                child: Container(
                  width: 140,
                  height: 120,
                  child: Image.asset(
                    appLogo, // Using the logo defined in constant.dart
                    fit: BoxFit.cover, // Adjust the image to fit within the container
                  ),
                ),
              ),
            ),

            // White login panel
            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      const Center(
                        child: Text(
                          "Login",
                          style: TextStyle(
                            fontSize: 40,
                            color: Colors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      CustomInputField(
                        label: "Email",
                        controller: _emailController,
                        hintText: "username@ws02.com",
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      CustomInputField(
                        label: "Password",
                        controller: _passwordController,
                        isPassword: true,
                        hintText: "••••••••••••••••",
                      ),
                      const SizedBox(height: 40),
                      CustomButton(
                        text: "Login",
                        onPressed: () {
                          // Handle login logic
                          Navigator.pushNamed(context, '/home');
                        },
                      ),
                      const Spacer(),
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // Navigate to sign up
                            Navigator.pushNamed(context, '/main');
                          },
                          child: const Text(
                            "Don't have an account? Sign Up here",
                            style: TextStyle(color: Colors.black, fontSize: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
