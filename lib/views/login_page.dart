import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/views/main_navigation.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

    Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }
    
    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/api/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['role'] == 'driver' && data['status'] == 'approved') {
          await _secureStorage.write(key: 'userData', value: jsonEncode(data));

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigation(userRole: UserRole.driver),
            ),
          );
        } else if (data['role'] == 'passenger' && data['status'] == 'approved'){
          await _secureStorage.write(key: 'userData', value: jsonEncode(data));
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MainNavigation(userRole: UserRole.passenger),
            ),
          );
        } else if( data['status'] != 'approved'){
          Navigator.of(context,).pushReplacementNamed('/waiting');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid credentials or server error')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: SizedBox(
                  width: 140,
                  height: 120,
                  child: Image.asset(appLogo, fit: BoxFit.cover),
                ),
              ),
            ),

            Expanded(
              flex: 4,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: bgcolor,
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
                            fontWeight: FontWeight.normal,
                            fontFamily: 'Inter',
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
                        onPressed: _login,
                        // onPressed: () async {
                          // Navigator.pushReplacement(
                          //   context,
                          //   MaterialPageRoute(
                          //     builder:
                          //         (context) => const MainNavigation(
                          //           userRole: UserRole.driver,
                          //         ),
                          //   ),
                          // );

                      //     final email = _emailController.text.trim();
                      //     final password = _passwordController.text;

                      //     if (email.isEmpty || password.isEmpty) {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(content: Text('Please enter email and password')),
                      //       );
                      //       return;
                      //     }

                      //     final response = await http.post(
                      //       Uri.parse('http://10.0.2.2:8080/api/login'),  // Replace with your actual endpoint
                      //       headers: {'Content-Type': 'application/json'},
                      //       body: jsonEncode({'email': email, 'password': password}),
                      //     );

                      //     if (response.statusCode == 200) {
                      //       final data = jsonDecode(response.body);

                      //       if (data['role'] == 'driver' && data['status'] == 'approved') {
                             
                      //         // Store token or data if needed

                      //         Navigator.pushReplacement(
                      //           context,
                      //           MaterialPageRoute(
                      //             builder: (context) => const MainNavigation(userRole: UserRole.driver),
                      //           ),
                      //         );
                      //       } else {
                      //         ScaffoldMessenger.of(context).showSnackBar(
                      //           SnackBar(content: Text('Login failed or account not approved')),
                      //         );
                      //       }
                      //     } else {
                      //       ScaffoldMessenger.of(context).showSnackBar(
                      //         SnackBar(content: Text('Invalid credentials or server error')),
                      //       );
                      //     }
                      //   },
                      ),
                      const Spacer(),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "didn't have an account? ",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(
                                    context,
                                  ).pushReplacementNamed('/signup');
                                },
                                child: const Text(
                                  'Sign Up here',
                                  style: TextStyle(
                                    color: linkColor,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
