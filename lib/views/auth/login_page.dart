import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/views/main_navigation.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/services/auth_services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _storage = FlutterSecureStorage();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final loginData = {
      'email': _emailController.text,
      'password': _passwordController.text,
    };

    try {
      final response = await ApiService.loginUser(loginData);
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final token = responseBody['token'];

        await _storage.write(
          key: 'jwt_token',
          value: token,
        );

        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        await prefs.setString('token', token);
        final userRole = decodedToken['role'];
        final firstName = decodedToken['firstName'];
        final lastName = decodedToken['lastName'];
        await prefs.setString('firstName', firstName);
        await prefs.setString('lastName', lastName);
        if (decodedToken['status'] == 'pending' && userRole != 'admin') {
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
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
        child: Stack(
          children: [
            Column(
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
                            text: _isLoading ? "Logging in..." : "Login",
                            onPressed: _isLoading ? null : _handleLogin,
                          ),
                          const Spacer(),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Didn't have an account? ",
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 14,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushReplacementNamed(context, '/signup');
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
            if (_isLoading)
              Container(
                color: primaryColor.withOpacity(0.8),
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(mainButtonColor),
                    strokeWidth: 4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}