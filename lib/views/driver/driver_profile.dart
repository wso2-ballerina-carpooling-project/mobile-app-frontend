import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:image_picker/image_picker.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        elevation: 8,
        title: Text('Logout', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Colors.black87, fontSize: 16)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: linkColor, fontSize: 16, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(side: BorderSide(color: linkColor, width: 1), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            style: TextButton.styleFrom(backgroundColor: mainButtonColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _storage.delete(key: 'jwt_token');
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error during logout: $e')));
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
                          backgroundImage: _imageFile != null ? FileImage(_imageFile!) as ImageProvider : NetworkImage(profileImageUrl),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.black54),
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
                        const Text('Hi there,', style: TextStyle(color: Colors.white, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(userName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600)),
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
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: blackWithOpacity)),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _infoCard('Pending Payment (Rs)', 'Rs. 12,000', 'From 20 rides'),
                            const SizedBox(width: 15),
                            _infoCard('Total Earned (Rs)', 'Rs. 32,000', 'From 52 rides', isRight: true),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text('Your Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: blackWithOpacity)),
                      const SizedBox(height: 20),
                      ListTile(
                        leading: const Icon(Icons.person_pin_rounded, color: Colors.black54),
                        title: const Text('Profile Picture'),
                        trailing: GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundImage: _imageFile != null ? FileImage(_imageFile!) as ImageProvider : NetworkImage(profileImageUrl),
                          ),
                        ),
                        onTap: _showImageSourceActionSheet,
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/nameEdit',
                            arguments: {'firstName': firstName, 'lastName': lastName},
                          ) as Map<String, dynamic>?;
                          if (result != null) {
                            setState(() {
                              firstName = result['firstName'] ?? firstName;
                              lastName = result['lastName'] ?? lastName;
                              userName = '$firstName $lastName';
                            });
                            await _loadUserData(); // Reload data to sync with new token
                          }
                        },
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.black54),
                          title: const Text('Name'),
                          subtitle: Text(userName),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () async {
                          final result = await Navigator.pushNamed(
                            context,
                            '/phoneEdit',
                            arguments: userPhone,
                          ) as String?;
                          if (result != null) {
                            setState(() {
                              userPhone = result;
                            });
                            await _loadUserData(); // Reload data to sync with new token
                          }
                        },
                        child: ListTile(
                          leading: const Icon(Icons.phone, color: Colors.black54),
                          title: const Text('Phone'),
                          subtitle: Text(userPhone),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
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
                        onTap: () {
                          Navigator.pushNamed(context, '/vehicleEdit');
                        },
                        child: const ListTile(
                          leading: Icon(Icons.directions_car, color: Colors.black54),
                          title: Text('Vehicle Details'),
                          subtitle: Text('View Details'),
                          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Need a lift? Be a ',
                            style: TextStyle(color: Colors.black87),
                            children: [TextSpan(text: 'Passenger', style: TextStyle(color: linkColor))],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: logout,
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Monthly Report ',
                            style: TextStyle(color: Colors.black87),
                            children: [TextSpan(text: 'Download Here', style: TextStyle(color: Color.fromRGBO(71, 71, 231, 1)))],
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

  Widget _infoCard(String title, String value, String subtitle, {bool isRight = false}) {
    return Container(
      width: 250,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRight ? const BorderSide(color: Colors.black, width: 1) : BorderSide.none,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isRight ? null : const LinearGradient(colors: [primaryColor, Color.fromRGBO(74, 94, 170, 1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            color: isRight ? Colors.white : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: isRight ? Colors.black54 : Colors.white70, fontSize: 16)),
              const SizedBox(height: 20),
              Text(value, style: TextStyle(color: isRight ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 36, height: 1)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 10, color: isRight ? const Color.fromRGBO(10, 14, 42, 1) : companyColor),
                  const SizedBox(width: 4),
                  Text(subtitle, style: TextStyle(color: isRight ? Colors.black54 : Colors.white70, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}