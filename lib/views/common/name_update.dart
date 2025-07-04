import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/services/profile_service.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NameUpdateScreen extends StatefulWidget {
  const NameUpdateScreen({Key? key}) : super(key: key);

  @override
  State<NameUpdateScreen> createState() => _NameUpdateScreenState();
}

class _NameUpdateScreenState extends State<NameUpdateScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {'firstName': 'Unknown User', 'lastName': 'Unknown User'};
    if (_firstNameController.text != (args['firstName'] as String? ?? 'Unknown User') ||
        _lastNameController.text != (args['lastName'] as String? ?? 'Unknown User')) {
      setState(() {
        _firstNameController.text = args['firstName'] as String? ?? 'Unknown User';
        _lastNameController.text = args['lastName'] as String? ?? 'Unknown User';
      });
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _updateDriverName() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final storage = const FlutterSecureStorage();
        final token = await storage.read(key: 'jwt_token') ?? '';

        final nameData = {
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
        };

        final response = await ProfileService.editName(nameData, token);

        if (response.statusCode == 200) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Name updated successfully!')),
          );
          // Check for new token in response headers
          final newToken = response.headers['authorization']?.replaceFirst('Bearer ', '') ?? token;
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
            final payload = Jwt.parseJwt(newToken);
            final updatedFirstName = payload['firstName'] ?? _firstNameController.text;
            final updatedLastName = payload['lastName'] ?? _lastNameController.text;
            setState(() {
              _firstNameController.text = updatedFirstName;
              _lastNameController.text = updatedLastName;
            });
          }
          final updatedData = {
            'firstName': _firstNameController.text,
            'lastName': _lastNameController.text,
          };
          Navigator.pop(context, updatedData);
        } else {
          throw Exception('Failed to update name: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update name: $e')),
        );
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
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
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
                            CustomInputField(
                              controller: _firstNameController,
                              label: 'First Name',
                              hintText: 'John',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your first name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            CustomInputField(
                              controller: _lastNameController,
                              label: 'Last Name',
                              hintText: 'Wick',
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your last name';
                                }
                                return null;
                              },
                            ),
                            const Spacer(),
                            CustomButton(
                              text: 'Save',
                              backgroundColor: mainButtonColor,
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