import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  // Controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor:
          primaryColor, // Dark background color from your constants
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Sign Up',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30,
            fontWeight: FontWeight.w300,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // White container positioned from the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.85, // Adjust as needed
            child: Container(
              decoration: const BoxDecoration(
                color: bgcolor, // Using your bgcolor constant
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Form fields
                      CustomInputField(
                        label: 'First name',
                        controller: _firstNameController,
                        hintText: 'John',
                      ),

                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Last name',
                        controller: _lastNameController,
                        hintText: 'Wick',
                      ),

                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Email',
                        controller: _emailController,
                        hintText: 'username@web02.com',
                        keyboardType: TextInputType.emailAddress,
                      ),

                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Phone',
                        controller: _phoneController,
                        hintText: '071 929 7961',
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Password',
                        controller: _passwordController,
                        isPassword: true,
                        hintText: '••••••••••••••••••',
                      ),

                      const SizedBox(height: 10),
                      CustomInputField(
                        label: 'Confirm password',
                        controller: _confirmPasswordController,
                        isPassword: true,
                        hintText: '••••••••••••••••••',
                      ),

                      // Terms and conditions checkbox
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (value) {
                                setState(() {
                                  _agreedToTerms = value ?? false;
                                });
                              },
                              fillColor: MaterialStateProperty.resolveWith<
                                Color
                              >((Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.blue;
                                }
                                return Colors.grey;
                              }),
                            ),
                            const Text(
                              'I agree term and condition',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Sign Up button
                      CustomButton(
                        text: 'Sign Up',
                        onPressed: () {
                          // Implement sign up logic
                           Navigator.of(
                                  context,
                                ).pushReplacementNamed('/role');
                          if (_agreedToTerms) {
                            // Proceed with sign up
                          } else {
                            // Show error for terms agreement
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor:
                                    Colors
                                        .red, // background color of the SnackBar
                                content: Text(
                                  'Please agree to the terms and conditions',
                                  style: TextStyle(
                                    color: Colors.white, // text color
                                    fontSize: 16, // text size
                                    fontWeight: FontWeight.bold, // text weight
                                     // custom font (make sure you added it)
                                  ),
                                ),
                                behavior:
                                    SnackBarBehavior
                                        .floating, // optional: makes it float
                                shape: RoundedRectangleBorder(
                                  // optional: rounded corners
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 10, // optional: shadow effect
                                duration: Duration(
                                  seconds: 3,
                                ), // how long it shows
                              ),
                            );
                          }
                        },
                      ),

                      // Already have an account link
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                // Navigate to login screen
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login');
                              },
                              child: const Text(
                                'Sign in here',
                                style: TextStyle(
                                  color: Color(0xFF5D5FEF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
