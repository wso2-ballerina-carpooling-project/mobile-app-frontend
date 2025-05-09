import 'package:flutter/material.dart';

Widget StopInfoCard({
    required String label,
    required int minutes,
    required String driverName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'In $minutes Mins',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              // Move profile image and name to be stacked vertically
              Column(
                children: [
                  const CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(
                      'https://via.placeholder.com/150', // Replace with actual driver image
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    driverName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.phone, size: 20, color: Colors.blue),
              const SizedBox(width: 14),
              const Icon(Icons.message, size: 20, color: Colors.blue),
            ],
          ),
        ],
      ),
    );
  }