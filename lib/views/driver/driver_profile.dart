import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

class DriverProfilePage extends StatefulWidget {
  const DriverProfilePage({super.key});

  @override
  State<DriverProfilePage> createState() => _DriverProfilePageState();
}

class _DriverProfilePageState extends State<DriverProfilePage> {
  String profileImageUrl = 'https://i.pravatar.cc/150?img=33';
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  final _storage = const FlutterSecureStorage();
  bool _isLoading = true;
  bool _isEarningsLoading = true;

  // User data
  String firstName = '';
  String lastName = '';
  String userName = '';
  String userPhone = '';
  String userEmail = '';
  // Earnings data
  double pendingEarnings = 0.0;
  double totalEarnings = 0.0;
  int totalRideCount = 0;
  int pendingPaymentRideCount = 0;

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
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
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (selectedOption == 'Custom' && selectedRange == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please select a date range')),
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

      // Set user data immediately
      setState(() {
        firstName = payload['firstName'] ?? 'Unknown User';
        lastName = payload['lastName'] ?? 'Unknown User';
        userPhone = payload['phone'] ?? 'Not Provided';
        userEmail = payload['email'] ?? 'Not Provided';
        userName = '$firstName $lastName';
        _isLoading = false;
      });

      // Fetch earnings data asynchronously
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['id'] ?? '';
      if (userId.isNotEmpty) {
        await _fetchEarnings(userId, token);
      } else {
        throw Exception('User ID not found in JWT token');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading user data: $e')));
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _fetchEarnings(String userId, String token) async {
    const String baseUrl =
        'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';
    final url = Uri.parse('$baseUrl/earnings');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'userId': userId}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          pendingEarnings =
              (data['pendingEarnings'] as num?)?.toDouble() ?? 0.0;
          totalEarnings = (data['totalEarnings'] as num?)?.toDouble() ?? 0.0;
          totalRideCount = (data['totalRideCount'] as num?)?.toInt() ?? 0;
          pendingPaymentRideCount =
              (data['pendingPaymentRideCount'] as num?)?.toInt() ?? 0;
          _isEarningsLoading = false;
        });
      } else {
        throw Exception('Failed to fetch earnings: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error fetching earnings: $e')));
      setState(() {
        pendingEarnings = 0.0;
        totalEarnings = 0.0;
        totalRideCount = 0;
        pendingPaymentRideCount = 0;
        _isEarningsLoading = false;
      });
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
            title: const Text(
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

  Widget _buildEarningsPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: 250,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(width: 150, height: 16, color: Colors.white),
                const SizedBox(height: 20),
                Container(width: 100, height: 36, color: Colors.white),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(width: 10, height: 10, color: Colors.white),
                    const SizedBox(width: 4),
                    Container(width: 80, height: 10, color: Colors.white),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                        'Your Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: blackWithOpacity,
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _isEarningsLoading
                                ? _buildEarningsPlaceholder()
                                : _infoCard(
                                  'Pending Payment (Rs)',
                                  'Rs. ${pendingEarnings.toStringAsFixed(2)}',
                                  'From $pendingPaymentRideCount ride${pendingPaymentRideCount == 1 ? '' : 's'}',
                                ),
                            const SizedBox(width: 15),
                            _isEarningsLoading
                                ? _buildEarningsPlaceholder()
                                : _infoCard(
                                  'Total Earned (Rs)',
                                  'Rs. ${totalEarnings.toStringAsFixed(2)}',
                                  'From $totalRideCount ride${totalRideCount == 1 ? '' : 's'}',
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
                            await _loadUserData();
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
                        onTap: () {
                          Navigator.pushNamed(context, '/vehicleEdit');
                        },
                        child: const ListTile(
                          leading: Icon(
                            Icons.directions_car,
                            color: Colors.black54,
                          ),
                          title: Text('Vehicle Details'),
                          subtitle: Text('View Details'),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 20),
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
                                    'Switch to Passenger?',
                                    style: TextStyle(
                                      color: Colors.black87,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  content: const Text(
                                    'Are you sure you want to switch your role to Passenger?',
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
                                  'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0/changeroletopassenger';

                              final response = await http.post(
                                Uri.parse(endpointUrl),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                              );

                              if (response.statusCode == 200) {
                                await _storage.deleteAll();
                                if (!mounted) return;
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              } else {
                                throw Exception(
                                  "Failed with status: ${response.statusCode}",
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

  Widget _infoCard(
    String title,
    String value,
    String subtitle, {
    bool isRight = false,
  }) {
    return Container(
      width: 250,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side:
              isRight
                  ? const BorderSide(color: Colors.black, width: 1)
                  : BorderSide.none,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient:
                isRight
                    ? null
                    : const LinearGradient(
                      colors: [primaryColor, Color.fromRGBO(74, 94, 170, 1)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            color: isRight ? Colors.white : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: isRight ? Colors.black54 : Colors.white70,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                value,
                style: TextStyle(
                  color: isRight ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 36,
                  height: 1,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 10,
                    color:
                        isRight
                            ? const Color.fromRGBO(10, 14, 42, 1)
                            : companyColor,
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
