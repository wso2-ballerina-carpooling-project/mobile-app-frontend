import 'package:flutter/material.dart';
import '../models/notification_item.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample notification data
    final List<NotificationItem> notifications = [
      NotificationItem(
        title: "New ride request",
        message: "John Smith wants to join your ride to Town",
        time: "2 minutes ago",
        isRead: false,
        icon: Icons.person_add,
      ),
      NotificationItem(
        title: "Ride confirmed",
        message: "Your ride to Marina Mall has been confirmed",
        time: "25 minutes ago",
        isRead: false,
        icon: Icons.check_circle,
      ),
      NotificationItem(
        title: "Payment received",
        message: "You received \$5.50 for your recent ride",
        time: "Yesterday",
        isRead: true,
        icon: Icons.attach_money,
      ),
      NotificationItem(
        title: "Ride canceled",
        message: "Your scheduled ride to Downtown was canceled",
        time: "2 days ago",
        isRead: true,
        icon: Icons.cancel,
      ),
      NotificationItem(
        title: "Rate your driver",
        message: "How was your ride with Alex? Please rate your experience",
        time: "3 days ago",
        isRead: true,
        icon: Icons.star_border,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color.fromRGBO(10, 14, 42, 1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            
            // Content area with only left side rounded
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                  ),
                ),
                child: notifications.isEmpty
                    ? _buildEmptyState()
                    : _buildNotificationsList(notifications),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
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
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Add notification settings action here
            },
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
                onPressed: () {
                  // Mark all as read action
                },
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
                child: Icon(
                  notification.icon,
                  color: notification.isRead ? Colors.grey[600] : Colors.blue[700],
                  size: 20,
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