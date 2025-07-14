import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:http/http.dart' as http; // Added for API call
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // Added for JWT token
import 'dart:convert'; // Added for JSON decoding
import '../../models/notification_item.dart';
import 'dart:math' as math;

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final storage = FlutterSecureStorage();
  String? jwtToken;
  Future<List<NotificationItem>>? _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _loadJwtToken();
  }

  Future<void> _loadJwtToken() async {
    final token = await storage.read(key: 'jwt_token');
    setState(() {
      jwtToken = token;
      if (jwtToken != null) {
        _notificationsFuture = _fetchNotifications();
      }
    });
  }

  Future<List<NotificationItem>> _fetchNotifications() async {
    if (jwtToken == null) {
      throw Exception('Authentication token not available');
    }

    const String baseUrl = 'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0'; // Adjust IP as needed
    final url = Uri.parse('$baseUrl/notifications');
    print('Requesting: $url with token: $jwtToken');

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $jwtToken',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> notifications = data['queryResult'] as List<dynamic>;
        return notifications.map((json) {
          final createdAtString = json['createdAt'] as String;
          final createdAtList = jsonDecode(createdAtString) as List<dynamic>;
          final timestamp = (createdAtList[0] as num).toInt(); // Extract integer part
          final timeAgo = _formatTimeAgo(timestamp);
          return NotificationItem(
            title: json['title'] as String,
            message: json['massage'] as String, // Correct field name
            time: timeAgo,
            isRead: json['isread'] as bool, // Correct field name
          );
        }).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.body}');
      }
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  String _formatTimeAgo(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000; // Current time in seconds
    final difference = now - timestamp;

    if (difference < 60) {
      return 'just now';
    } else if (difference < 3600) {
      final minutes = (difference / 60).floor();
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference < 86400) {
      final hours = (difference / 3600).floor();
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference < 604800) {
      final days = (difference / 86400).floor();
      return '$days day${days > 1 ? 's' : ''} ago';
    } else {
      final weeks = (difference / 604800).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }
  }

  void _markAllAsRead() {
    // Implement API call to mark all as read if needed
    setState(() {
      if (_notificationsFuture != null) {
        _notificationsFuture = _fetchNotifications(); // Refresh data
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: _notificationsFuture == null
                    ? const Center(child: CircularProgressIndicator())
                    : FutureBuilder<List<NotificationItem>>(
                        future: _notificationsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }
                          final notifications = snapshot.data!;
                          return _buildNotificationsList(notifications);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 25.0, bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Notifications",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_none,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No Notifications",
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationItem> notifications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Recent",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  "Mark all as read",
                  style: TextStyle(
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              return NotificationListItem(notification: notifications[index]);
            },
          ),
        ),
      ],
    );
  }
}

class NotificationListItem extends StatelessWidget {
  final NotificationItem notification;

  const NotificationListItem({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : Colors.blue.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: notification.isRead ? Colors.grey[200] : Colors.blue[100],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Divider(
          color: Colors.grey.shade200,
          thickness: 1.0,
          height: 1.0,
        ),
      ],
    );
  }
}