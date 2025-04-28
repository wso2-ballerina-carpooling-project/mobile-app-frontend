import 'dart:io';
import 'package:flutter/material.dart';
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
  
  // User data
  String userName = 'Nalaka Dinesh';
  String userPhone = '071 929 7961';
  String userEmail = 'nalaka@wso2.com';

  Future<void> _pickImage(ImageSource source) async {
    final XFile? selectedImage = await _picker.pickImage(source: source);
    
    if (selectedImage != null) {
      setState(() {
        _imageFile = File(selectedImage.path);
      });
      // Here you would typically upload the image to your server
      // and update profileImageUrl with the new URL
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

            // Profile and name aligned left - FIXED SECTION
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
                          backgroundImage: _imageFile != null 
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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi there,',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
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

            const SizedBox(height: 20),

            // White Container with SingleChildScrollView - SCROLLABLE SECTION
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
                      const Text(
                        'Your Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: blackWithOpacity
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _infoCard(
                              'Pending Payment (Rs)',
                              'Rs. 12,000',
                              'From 20 rides',
                            ),
                            const SizedBox(width: 15),
                            _infoCard(
                              'Total Earned (Rs)',
                              'Rs. 32,000',
                              'From 52 rides',
                              isRight: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      const Text(
                        'Your Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: blackWithOpacity
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Picture ListTile
                      ListTile(
                        leading: const Icon(Icons.person_pin_rounded, color: Colors.black54),
                        title: const Text('Profile Picture'),
                        trailing: GestureDetector(
                          onTap: _showImageSourceActionSheet,
                          child: CircleAvatar(
                            radius: 15,
                            backgroundImage: _imageFile != null 
                                ? FileImage(_imageFile!) as ImageProvider
                                : NetworkImage(profileImageUrl),
                          ),
                        ),
                        onTap: _showImageSourceActionSheet,
                      ),
                      const Divider(height: 1),
                      
                      // Name - editable
                      InkWell(
                        onTap: () {
                                  Navigator.of(context).pushReplacementNamed('/nameEdit');
                        },
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.black54),
                          title: const Text('Name'),
                          subtitle: Text(userName),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // Phone - editable
                      InkWell(
                        onTap: () {
                                  Navigator.of(context).pushReplacementNamed('/phoneEdit');
                                },
                        child: ListTile(
                          leading: const Icon(Icons.phone, color: Colors.black54),
                          title: const Text('Phone'),
                          subtitle: Text(userPhone),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.black54),
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // Email - not editable
                      ListTile(
                        leading: const Icon(Icons.email, color: Colors.black54),
                        title: const Text('Email'),
                        subtitle: Text(userEmail),
                        // No trailing arrow as it's not editable
                      ),
                      const Divider(height: 1),
                      
                      // Vehicle Details - editable
                      InkWell(
                        onTap: () {
                                  Navigator.of(context).pushReplacementNamed('/vehicleEdit');
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
                            children: [
                              TextSpan(
                                text: 'Passenger',
                                style: TextStyle(color: linkColor),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
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
                      const Center(
                        child: Text.rich(
                          TextSpan(
                            text: 'Monthly Report ',
                            style: TextStyle(color: Colors.black87),
                            children: [
                              TextSpan(
                                text: 'Download Here',
                                style: TextStyle(color: linkColor),
                              ),
                            ],
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

  // Updated infoCard function to match the image
  Widget _infoCard(
    String title,
    String value,
    String subtitle, {
    bool isRight = false,
  }) {
    return Container(
      width: 250, // Fixed width for consistent card size
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isRight
              ? const BorderSide(color: Colors.black, width: 1)
              : BorderSide.none,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isRight
                ? null // No gradient for the right-side box
                : const LinearGradient(
                    colors: [
                      primaryColor, // Darker blue as in image
                      mainButtonColor, // Lighter blue as in image
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: isRight ? Colors.white : null, // Fallback for right-side box
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title at top
              Text(
                title,
                style: TextStyle(
                  color: isRight ? Colors.black54 : Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              
              // Value (large text)
              Text(
                value,
                style: TextStyle(
                  color: isRight ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36, // Much larger as in image
                  height: 1, // Tight line height
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle with location icon
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined, // Location icon
                    size: 10,
                    color: isRight ? primaryColor : companyColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isRight ? Colors.black54 : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

