import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/services/auth_services.dart';

class ResetPasswordPage extends StatefulWidget {
  final String? email;
  
  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isResendingOTP = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill email if passed from previous screen
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors in the form')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final resetData = {
      'email': _emailController.text,
      'otp': _otpController.text,
      'newPassword': _passwordController.text,
    };

    try {
      final response = await ApiService.resetpass(resetData);
      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back to login page
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        final errorMessage = jsonDecode(response.body)['message'] ?? 'Failed to reset password';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
                  // Top section with logo
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.35,
                            height: MediaQuery.of(context).size.height * 0.15,
                            child: Image.asset(appLogo, fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 10),
                          
                        ],
                      ),
                    ),
                  ),
                  // Bottom section with form
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
                                height: MediaQuery.of(context).size.height * 0.015,
                              ),
                              const Center(
                                child: Text(
                                  "Enter New Password",
                                  style: TextStyle(
                                    fontSize: 28,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01,
                              ),
                              const Center(
                                child: Text(
                                  "Enter the OTP sent to your email and create a new password",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.025,
                              ),
                              // Email Field
                              
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.015,
                              ),
                              // OTP Field
                              CustomInputField(
                                label: "OTP",
                                controller: _otpController,
                                hintText: "Enter 4-digit OTP",
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the OTP';
                                  }
                                  if (value.length != 4) {
                                    return 'OTP must be 4 digits';
                                  }
                                  return null;
                                },
                              ),
                              // Resend OTP Link
                              
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.01,
                              ),
                              // New Password Field
                              CustomInputField(
                                label: "New Password",
                                controller: _passwordController,
                                isPassword: true,
                                hintText: "••••••••••••••••",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your new password';
                                  }
                                  if (value.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.015,
                              ),
                              // Confirm Password Field
                              CustomInputField(
                                label: "Confirm Password",
                                controller: _confirmPasswordController,
                                isPassword: true,
                                hintText: "••••••••••••••••",
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.025,
                              ),
                              // Reset Password Button
                              CustomButton(
                                text: _isLoading ? "Resetting Password..." : "Reset Password",
                                onPressed: _isLoading ? null : _handleResetPassword,
                                useGradient: false,
                                gradientColors: [mainButtonColor, primaryColor],
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.height * 0.02,
                              ),
                              // Back to Login Link
                              Center(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text(
                                      "Remember your password? ",
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.pushReplacementNamed(context, '/login');
                                      },
                                      child: const Text(
                                        'Back to Login',
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
                                height: MediaQuery.of(context).size.height * 0.02,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              // Loading Overlay
              if (_isLoading)
                Container(
                  color: primaryColor.withOpacity(0.8),
                  child: Center(
                    child: Semantics(
                      label: 'Resetting password, please wait',
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(mainButtonColor),
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