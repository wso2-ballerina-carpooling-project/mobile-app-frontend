import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/services/profile_service.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhoneUpdate extends StatefulWidget {
  const PhoneUpdate({Key? key}) : super(key: key);

  @override
  State<PhoneUpdate> createState() => _PhoneUpdateState();
}

class _PhoneUpdateState extends State<PhoneUpdate> {
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phone =
        ModalRoute.of(context)!.settings.arguments as String? ?? 'Not Provided';
    if (_phoneController.text != phone) {
      setState(() {
        _phoneController.text = phone;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _updatePhone() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'jwt_token') ?? '';

        final phoneData = {
          'phone': _phoneController.text,
        };

        final response = await ProfileService.editPhone(phoneData, token);

        if (response.statusCode == 200) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone updated successfully!')),
          );
          // Update the stored token or user data if the backend returns a new JWT
          final newToken =
              response.headers['authorization']?.replaceFirst('Bearer ', '') ??
              token;
          if (newToken != token) {
            await storage.write(key: 'jwt_token', value: newToken);
            final prefs = await SharedPreferences.getInstance();
            Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
            await prefs.setString('token', token);
            final firstName = decodedToken['firstName'];
            final lastName = decodedToken['lastName'];
            final id = decodedToken['id'];
            await prefs.setString('firstName', firstName);
            await prefs.setString('firstName', firstName);
            await prefs.setString('lastName', lastName);
            await prefs.setString('id', id);
            print("new jwt recieved");
          }
          // Return the updated phone to refresh the parent screen
          final updatedPhone = _phoneController.text;
          Navigator.pop(context, updatedPhone);
        } else {
          throw Exception('Failed to update phone: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update phone: $e')));
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Row with Back Arrow and Centered Title
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 40,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 30,
                          ),
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
                            CustomInputField(
                              controller: _phoneController,
                              label: 'Phone',
                              hintText: '0719297961',
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your phone number';
                                }
                                if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const Spacer(),
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
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
