import 'package:flutter/material.dart';
import 'package:mobile_frontend/widgets/custom_input_field_secoundary.dart';

class ExampleScreen extends StatefulWidget {
  const ExampleScreen({Key? key}) : super(key: key);

  @override
  _ExampleScreenState createState() => _ExampleScreenState();
}

class _ExampleScreenState extends State<ExampleScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Registration Form'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            
            // Name input field
            CustomInputFieldSecoundary(
              label: 'Name', // This won't be displayed but is still required
              controller: _nameController,
              hintText: 'Enter your full name',
              keyboardType: TextInputType.name,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Email input field
            CustomInputFieldSecoundary(
              label: 'Email',
              controller: _emailController,
              hintText: 'Enter your email address',
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email';
                } else if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
              suffixIcon: const Icon(Icons.email_outlined),
            ),
            
            const SizedBox(height: 16),
            
            // Password input field
            CustomInputFieldSecoundary(
              label: 'Password',
              controller: _passwordController,
              isPassword: true,
              hintText: 'Create a password',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                } else if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
              suffixIcon: const Icon(Icons.visibility_off),
            ),
            
            const SizedBox(height: 30),
            
            // Submit button
            ElevatedButton(
              onPressed: () {
                // Form validation logic here
                // You could use a Form widget with a GlobalKey<FormState> for validation
                print('Name: ${_nameController.text}');
                print('Email: ${_emailController.text}');
                print('Password: ${_passwordController.text}');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'REGISTER',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}