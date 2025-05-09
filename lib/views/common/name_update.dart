import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';

class NameUpdateScreen extends StatefulWidget {
  const NameUpdateScreen({Key? key}) : super(key: key);

  @override
  State<NameUpdateScreen> createState() => _NameUpdateScreenState();
}

class _NameUpdateScreenState extends State<NameUpdateScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  void _updateDriverName() {
    if (_formKey.currentState?.validate() ?? false) {
      // Proceed with updating the driver's name
      print("Driver Name Updated: ${_firstNameController.text} ${_lastNameController.text}");
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
                    'Name',
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
                          controller: _firstNameController,
                          label: 'First Name',
                          hintText: 'John',
                        ),
                        const SizedBox(height: 20),

                        // Last Name Input
                        CustomInputField(
                          controller: _lastNameController,
                          label: 'Last Name',
                          hintText: 'Wick',
                        ),

                        const Spacer(), // Pushes the button to bottom

                        // Save Button
                        CustomButton(
                          text: 'Save',
                          backgroundColor: btnColor,
                          onPressed: _updateDriverName,
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