import 'package:flutter/material.dart';
import '../models/last_trip.dart';

class LastTripItem extends StatelessWidget {
  final LastTrip trip;
  const LastTripItem({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 5),
          leading: const Icon(Icons.location_city_outlined, color: Colors.black54),
          title: Text(
            trip.locationName,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          subtitle: Text(
            trip.address,
            style: const TextStyle(color: Colors.black54),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'LKR 1,500', // Placeholder earned amount
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        // Horizontal rule
        Divider(
          color: Colors.grey.shade300,
          thickness: 1.0,
          height: 1.0,
        ),
      ],
    );
  }
}