// lib/views/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/common/activities_page.dart';
import 'package:mobile_frontend/views/driver/driver_home.dart';
import 'package:mobile_frontend/views/driver/driver_profile.dart';
import 'package:mobile_frontend/views/common/notification_page.dart';
import 'package:mobile_frontend/views/passenger/passenger_home.dart';
import 'package:mobile_frontend/views/passenger/passenger_profile.dart';

enum UserRole {
  driver,
  passenger,
}

class MainNavigation extends StatefulWidget {
  final UserRole userRole;

  const MainNavigation({
    super.key,
    required this.userRole,
  });

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Initialize screens based on user role
    _initScreens();
  }

  void _initScreens() {
    if (widget.userRole == UserRole.driver) {
      _screens = [
        const DriverHomeScreen(),
        const ActivitiesScreen(),
        const NotificationsScreen(),
        const DriverProfilePage(),
      ];
    } else {
      _screens = [
        const PassengerHome(),
        const ActivitiesScreen(),
        const NotificationsScreen(),
        const PassengerProfile(),
      ];
    }
  }

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
        userRole: widget.userRole,
      ),
    );
  }
}

class CustomTabBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final UserRole userRole;

  const CustomTabBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    // You can also customize the tab bar based on user role if needed
  
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
            label: "Home",
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
            label: "Profile",
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