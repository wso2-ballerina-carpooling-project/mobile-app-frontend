import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class PassengerProfile extends StatefulWidget {
  const PassengerProfile({super.key});

  @override
  State<PassengerProfile> createState() => _PassengerProfileState();
}

class _PassengerProfileState extends State<PassengerProfile> {
  String profileImageUrl = 'https://i.pravatar.cc/150?img=33';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _storage = FlutterSecureStorage();

  // User data
  String firstName = '';
  String lastName = '';
  String userName = '';
  String userPhone = '';
  String userEmail = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _generateReport(String type, DateTimeRange? range) {
    String message = 'Generating $type report';
    if (type == 'Custom' && range != null) {
      message +=
          ' from ${range.start.toLocal().toString().split(' ')[0]} to ${range.end.toLocal().toString().split(' ')[0]}';
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    // TODO: Call backend/report generation logic here
  }

  void _showReportDialog() {
    String selectedOption = 'Monthly';
    DateTimeRange? selectedRange;

    showDialog(
      context: context,
      builder: (context) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
            colorScheme: ColorScheme.light(
              primary: Color.fromRGBO(71, 71, 231, 1),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              Future<void> pickDateRange() async {
                final now = DateTime.now();
                final DateTimeRange? range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(now.year - 1),
                  lastDate: now,
                  helpText: 'Select Custom Date Range',
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: Color.fromRGBO(71, 71, 231, 1),
                          onPrimary: Colors.white,
                          surface: Colors.white,
                          onSurface: Colors.black87,
                        ),
                        textButtonTheme: TextButtonThemeData(
                          style: TextButton.styleFrom(
                            foregroundColor: Color.fromRGBO(71, 71, 231, 1),
                          ),
                        ),
                      ),
                      child: child!,
                    );
                  },
                );

                if (range != null) {
                  setState(() {
                    selectedRange = range;
                  });
                }
              }

              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Text(
                  'Download Report',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RadioListTile<String>(
                      activeColor: Color.fromRGBO(71, 71, 231, 1),
                      title: const Text('Monthly'),
                      value: 'Monthly',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                          selectedRange = null;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      activeColor: Color.fromRGBO(71, 71, 231, 1),
                      title: const Text('Weekly'),
                      value: 'Weekly',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                          selectedRange = null;
                        });
                      },
                    ),
                    RadioListTile<String>(
                      activeColor: Color.fromRGBO(71, 71, 231, 1),
                      title: const Text('Custom Date Range'),
                      value: 'Custom',
                      groupValue: selectedOption,
                      onChanged: (value) {
                        setState(() {
                          selectedOption = value!;
                        });
                        Future.delayed(Duration.zero, pickDateRange);
                      },
                    ),
                    if (selectedOption == 'Custom' && selectedRange != null)
                      Container(
                        margin: const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'From: ${selectedRange!.start.toLocal().toString().split(' ')[0]}\n'
                          'To: ${selectedRange!.end.toLocal().toString().split(' ')[0]}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromRGBO(71, 71, 231, 1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      if (selectedOption == 'Custom' && selectedRange == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a date range'),
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context);
                      _generateReport(selectedOption, selectedRange);
                    },
                    child: const Text('Download'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      Map<String, dynamic> payload;
      try {
        payload = Jwt.parseJwt(token);
      } catch (e) {
        await _storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      if (Jwt.isExpired(token)) {
        await _storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        return;
      }

      setState(() {
        firstName = payload['firstName'] ?? 'Unknown User';
        lastName = payload['lastName'] ?? 'Unknown User';
        userPhone = payload['phone'] ?? 'Not Provided';
        userEmail = payload['email'] ?? 'Not Provided';
        userName = '$firstName $lastName';
        _isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() => _imageFile = File(selectedImage.path));
      // TODO: Upload image to server and update profileImageUrl
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> logout() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            elevation: 8,
            title: Text(
              'Logout',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'Are you sure you want to log out?',
              style: TextStyle(color: Colors.black87, fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: linkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  side: BorderSide(color: linkColor, width: 1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: mainButtonColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      try {
        await _storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _showImageSourceActionSheet,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 35,
                          backgroundImage:
                              _imageFile != null
                                  ? FileImage(_imageFile!) as ImageProvider
                                  : NetworkImage(profileImageUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Hi there,',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: blackWithOpacity,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(
                          Icons.person_pin_rounded,
                          color: Colors.black54,
                        ),
                        title: const Text('Profile Picture'),
                        trailing: GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundImage:
                                _imageFile != null
                                    ? FileImage(_imageFile!) as ImageProvider
                                    : NetworkImage(profileImageUrl),
                          ),
                        ),
                        onTap: _showImageSourceActionSheet,
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () async {
                          final result =
                              await Navigator.pushNamed(
                                    context,
                                    '/nameEdit',
                                    arguments: {
                                      'firstName': firstName,
                                      'lastName': lastName,
                                    },
                                  )
                                  as Map<String, dynamic>?;
                          if (result != null) {
                            setState(() {
                              firstName = result['firstName'] ?? firstName;
                              lastName = result['lastName'] ?? lastName;
                              userName = '$firstName $lastName';
                            });
                            await _loadUserData();
                          }
                        },
                        child: ListTile(
                          leading: const Icon(
                            Icons.person,
                            color: Colors.black54,
                          ),
                          title: const Text('Name'),
                          subtitle: Text(userName),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () async {
                          final result =
                              await Navigator.pushNamed(
                                    context,
                                    '/phoneEdit',
                                    arguments: userPhone,
                                  )
                                  as String?;
                          if (result != null) {
                            setState(() {
                              userPhone = result;
                            });
                            await _loadUserData(); // Reload data to sync with new token
                          }
                        },
                        child: ListTile(
                          leading: const Icon(
                            Icons.phone,
                            color: Colors.black54,
                          ),
                          title: const Text('Phone'),
                          subtitle: Text(userPhone),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.black54),
                        title: const Text('Email'),
                        subtitle: Text(userEmail),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () async {
                          bool? confirm = await showDialog<bool>(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  backgroundColor: Colors.white,
                                  elevation: 8,
                                  title: const Text(
                                    'Switch to Driver?',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to switch your role to Driver?',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, false),
                                      child: const Text(
                                        'Cancel',
                                        style: TextStyle(
                                          color: linkColor,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        side: BorderSide(
                                          color: linkColor,
                                          width: 1,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed:
                                          () => Navigator.pop(context, true),
                                      child: const Text(
                                        'Confirm',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: mainButtonColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            5,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );

                          if (confirm == true) {
                            try {
                              final token = await _storage.read(
                                key: 'jwt_token',
                              );
                              if (token == null)
                                throw Exception("JWT token not found");

                              const String endpointUrl =
                                  'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0/changeroletodriver';

                              final response = await http.post(
                                Uri.parse(endpointUrl),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                              );

                              if(response.statusCode == 201){
                                 Navigator.pushNamed(
                                  context,
                                  '/vehicleEdit'
                                );
                              }

                              if (response.statusCode == 200) {
                                await _storage.deleteAll();
                                if (!mounted) return;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              } 
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        },

                        child: const Center(
                          child: Text.rich(
                            TextSpan(
                              text: 'Got a seat? Be a ',
                              style: TextStyle(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Driver',
                                  style: TextStyle(color: linkColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: logout,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: GestureDetector(
                          onTap: _showReportDialog,
                          child: Text.rich(
                            TextSpan(
                              text: 'Monthly Report ',
                              style: const TextStyle(color: Colors.black87),
                              children: [
                                TextSpan(
                                  text: 'Download Here',
                                  style: const TextStyle(
                                    color: Color.fromRGBO(71, 71, 231, 1),
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
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
