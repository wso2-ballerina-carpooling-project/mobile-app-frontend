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
  final TextEditingController _forgotEmailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _storage = FlutterSecureStorage();
  bool _isLoading = false;
  bool _isForgotPasswordLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _forgotEmailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form')),
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

        await _storage.write(key: 'jwt_token', value: token);

        Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
        await prefs.setString('token', token);
        final userRole = decodedToken['role'];
        final firstName = decodedToken['firstName'];
        final lastName = decodedToken['lastName'];
        final id = decodedToken['id'];
        await prefs.setString('firstName', firstName);
        await prefs.setString('firstName', firstName);
        await prefs.setString('lastName', lastName);
        await prefs.setString('id', id);
        String? FCM = await prefs.getString("fcm");
        await ApiService.sendFCM(FCM,id);
        if (decodedToken['status'] == 'pending' && userRole != 'admin') {
          Navigator.pushReplacementNamed(context, '/waiting');
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => MainNavigation(
                    userRole:
                        userRole == 'driver'
                            ? UserRole.driver
                            : UserRole.passenger,
                  ),
            ),
          );
        }
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Login failed';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _handleForgotPassword(String email) async {
    setState(() {
      _isForgotPasswordLoading = true;
    });
    //  Navigator.pushNamed(context, '/reset-password', arguments: email);
    try {
      final response = await ApiService.sendotp(email);
      setState(() {
        _isForgotPasswordLoading = false;
      });

      if (response.statusCode == 200) {
        Navigator.of(context).pop(); // Close the dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP sent to your email successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // You can navigate to OTP verification page or handle as needed
        Navigator.pushNamed(context, '/reset-password', arguments: email);
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to send OTP';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isForgotPasswordLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showForgotPasswordDialog() {
    _forgotEmailController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Forgot Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address and we\'ll send you an OTP to reset your password.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  CustomInputField(
                    label: "Email",
                    controller: _forgotEmailController,
                    hintText: "Enter your email",
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isForgotPasswordLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: _isForgotPasswordLoading ? null : () {
                    if (_forgotEmailController.text.isNotEmpty &&
                        RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                            .hasMatch(_forgotEmailController.text)) {
                      _handleForgotPassword(_forgotEmailController.text);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a valid email address'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isForgotPasswordLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Send OTP'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.35,
                        height: MediaQuery.of(context).size.height * 0.15,
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
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(40),
                        ),
                      ),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(
                          MediaQuery.of(context).size.width * 0.06,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                              ),
                              const Center(
                                child: Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 32,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              CustomInputField(
                                label: "Email",
                                controller: _emailController,
                                hintText: "username@ws02.com",
                                keyboardType: TextInputType.emailAddress,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email';
                                  }
                                  if (!RegExp(
                                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                                  ).hasMatch(value)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                              ),
                              CustomInputField(
                                label: "Password",
                                controller: _passwordController,
                                isPassword: true,
                                hintText: "••••••••••••••••",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              // Forgot Password Button
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.01,
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: _showForgotPasswordDialog,
                                  child: const Text(
                                    'Forgot Password?',
                                    style: TextStyle(
                                      color: linkColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.015,
                              ),
                              CustomButton(
                                text: _isLoading ? "Logging in..." : "Login",
                                onPressed: _isLoading ? null : _handleLogin,
                                useGradient: false,
                                gradientColors: [mainButtonColor, primaryColor],
                              ),
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                              Center(
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
                                        Navigator.pushReplacementNamed(
                                          context,
                                          '/signup',
                                        );
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
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.02,
                              ),
                            ],
                          ),
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
                    child: Semantics(
                      label: 'Loading, please wait',
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          mainButtonColor,
                        ),
                        strokeWidth: 4,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}