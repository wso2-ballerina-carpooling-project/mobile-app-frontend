import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/services/auth_services.dart';

class RoleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const RoleSelectionScreen({super.key, required this.userData});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  bool _isLoading = false; // Track loading state

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Select Role',
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
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.85,
            child: Container(
              decoration: const BoxDecoration(
                color: bgcolor,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(40)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Are you a Driver or Passenger?',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 40),
                    CustomButton(
                      text: 'Driver',
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/driver-details',
                          arguments: widget.userData,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Passenger',
                      onPressed: () async {
                        setState(() {
                          _isLoading = true; // Set loading state to true before API call
                        });
                        await _registerUser(context, {...widget.userData, 'role': 'passenger'});
                        setState(() {
                          _isLoading = false; // Reset loading state after API call
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const Opacity(
              opacity: 0.8,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Colors.blue),
            ),
        ],
      ),
    );
  }

  Future<void> _registerUser(BuildContext context, Map<String, dynamic> data) async {
    try {
      final response = await ApiService.registerUser(data);
      if (response.statusCode == 201) {
        Navigator.pushReplacementNamed(context, '/waiting');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}