import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DriverDetailsPage(),
    );
  }
}

class DriverDetailsPage extends StatelessWidget {
  const DriverDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0C2C),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Profile and name aligned left
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 35,
                      backgroundImage: NetworkImage(
                        'https://i.pravatar.cc/150?img=33',
                      ),
                    ),
                    const SizedBox(width: 15),
                    const Expanded(
                      child: Text(
                        'Hi there,\nJohn Doe',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // White Container starts here
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Cards inside white container
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _infoCard(
                          'Balance (Rs)',
                          'Rs. 12,000',
                          'From 20 rides',
                        ),
                        _infoCard(
                          'Total Earned (Rs)',
                          'Rs. 32,000',
                          'From 52 rides',
                          isRight: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'Your Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Profile Picture ListTile
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile Picture'),
                      trailing: const CircleAvatar(
                        radius: 15,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=33',
                        ),
                      ),
                      onTap: () {},
                    ),
                    const Divider(height: 1),
                    _buildListTile(Icons.person, 'Name', 'Nalaka Dinesh'),
                    _buildListTile(Icons.phone, 'Phone', '071 929 7961'),
                    _buildListTile(Icons.email, 'Email', 'nalaka@wso2.com'),
                    _buildListTile(
                      Icons.directions_car,
                      'Vehicle Details',
                      'View Details',
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Need a lift? Be a ',
                          children: [
                            TextSpan(
                              text: 'Passenger',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Logout'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'Monthly Report ',
                          children: [
                            TextSpan(
                              text: 'Download Here',
                              style: TextStyle(color: Colors.blue),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(canvasColor: const Color(0xFF0D0C2C)),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 3,
          selectedItemColor: Colors.grey,
          unselectedItemColor: Colors.white,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Center(child: Icon(Icons.home)),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Center(child: Icon(Icons.menu)),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Center(child: Icon(Icons.notifications)),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: Center(child: Icon(Icons.person)),
              label: '',
            ),
          ],
        ),
      ),
    );
  }

  // Updated infoCard function
  static Widget _infoCard(
    String title,
    String value,
    String subtitle, {
    bool isRight = false,
  }) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side:
            isRight
                ? const BorderSide(color: Colors.black, width: 1)
                : BorderSide.none,
      ),
      color: isRight ? Colors.white : const Color(0xFF403FCC),
      child: Container(
        width: 160,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                color: isRight ? Colors.black54 : Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isRight ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: isRight ? Colors.black45 : Colors.white60,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildListTile(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: subtitle.isNotEmpty ? Text(subtitle) : null,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
