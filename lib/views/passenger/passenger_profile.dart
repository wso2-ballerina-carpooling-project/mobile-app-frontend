import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/helpers/auth_helper.dart'; // ✅ Import the logout helper

class PassengerProfile extends StatefulWidget {
  const PassengerProfile({super.key});

  @override
  State<PassengerProfile> createState() => _PassengerProfileState();
}

class _PassengerProfileState extends State<PassengerProfile> {
  String profileImageUrl = 'https://i.pravatar.cc/150?img=33';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  String userName = 'Nalaka Dinesh';
  String userPhone = '071 929 7961';
  String userEmail = 'nalaka@wso2.com';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    if (selectedImage != null) {
      setState(() {
        _imageFile = File(selectedImage.path);
      });
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

  @override
  Widget build(BuildContext context) {
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
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!) as ImageProvider
                          : NetworkImage(profileImageUrl),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Hi there,',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'John Doe',
                          style: TextStyle(
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
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 20),
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
                      const SizedBox(height: 10),
                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: _showImageSourceActionSheet,
                        child: const ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.person_outline, color: Colors.black54),
                          title: Text('Profile Picture'),
                          trailing: Icon(Icons.camera_alt, size: 18, color: Colors.grey),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/nameEdit');
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline, color: Colors.black54),
                          title: const Text('Name'),
                          subtitle: Text(userName),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ),
                      ),
                      const Divider(height: 1),
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/phoneEdit');
                        },
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.phone_outlined, color: Colors.black54),
                          title: const Text('Phone'),
                          subtitle: Text(userPhone),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                        ),
                      ),
                      const Divider(height: 1),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.email_outlined, color: Colors.black54),
                        title: const Text('Email'),
                        subtitle: Text(userEmail),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 60),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Switch accounts? Be a ',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: 'Driver',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: linkColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // ✅ Logout Button using helper
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            logout(context); // <--- logout function call
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: Colors.black12),
                          ),
                          child: const Text('Logout'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Monthly Report ',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            children: [
                              TextSpan(
                                text: 'Download Here',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: linkColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
