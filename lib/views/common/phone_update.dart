import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';

class PhoneUpdate extends StatefulWidget {
  const PhoneUpdate({Key? key}) : super(key: key);

  @override
  State<PhoneUpdate> createState() => _PhoneUpdateState();
}

class _PhoneUpdateState extends State<PhoneUpdate> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _updatePhone() {
    if (_formKey.currentState?.validate() ?? false) {
      // Proceed with updating the driver's name
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Blue background color
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Row with Back Arrow and Centered Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Go back
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    ),
                  ),
                  const Text(
                    'Phone',
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            // White Rectangle
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(50),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        // First Name Input
                        CustomInputField(
                          controller: _phoneController,
                          label: 'Phone',
                          hintText: '0719297961',
                        ),
                        const SizedBox(height: 20),

                        // Last Name Input
                       
                        const Spacer(), // Pushes the button to bottom

                        // Save Button
                        CustomButton(
                          text: 'Save',
                          backgroundColor: btnColor,
                          onPressed: _updatePhone,
                        ),
                      ],
                    ),
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
