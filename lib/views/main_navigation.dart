// lib/views/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/home_screen.dart';
// Import your actual screen implementations

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Replace these with your actual screen implementations
  final List<Widget> _screens = [
    const HomeScreen(),
    // const ActivitiesScreen(),
    // const NotificationsScreen(),
    // const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomTabBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}

class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTabItem(
            index: 0,
            icon: Icons.home_outlined,
            selectedIcon: Icons.home,
            label: 'Home',
          ),
          _buildTabItem(
            index: 1, 
            icon: Icons.list_alt_outlined,
            selectedIcon: Icons.list_alt,
            label: 'Activities',
          ),
          _buildTabItem(
            index: 2,
            icon: Icons.notifications_none_outlined,
            selectedIcon: Icons.notifications,
            label: 'Notifications',
          ),
          _buildTabItem(
            index: 3,
            icon: Icons.person_outline,
            selectedIcon: Icons.person,
            label: 'Account',
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
  }) {
    final isSelected = index == currentIndex;
    
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? const Color(0xFF1A2B47) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1A2B47) : Colors.grey,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}