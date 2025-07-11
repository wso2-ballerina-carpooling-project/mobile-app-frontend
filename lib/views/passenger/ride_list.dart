import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/passenger/ride_map.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class RideListScreen extends StatelessWidget {
  final List<Map<String, dynamic>> rides;
  final String waypoint;

  const RideListScreen({Key? key, required this.rides, required this.waypoint})
    : super(key: key);

  Future<void> _bookRide(
    BuildContext context,
    String rideId,
    String waypoint,
  ) async {
    print(rideId);
    final storage = FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'jwt_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No authentication token found. Please log in again.',
            ),
          ),
        );
        return;
      }

      const String baseUrl =
          'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';
      final url = Uri.parse('$baseUrl/rides/book');
      final body = jsonEncode({'rideId': rideId, 'waypoint': waypoint});

      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ride booked successfully!')),
        );

        // Extract driver's token from ride data or fetch it from backend
        final ride = rides.firstWhere((r) => r['rideId'] == rideId);
        final driverToken =
            ride['driverToken']; // Assume this is in the ride data
        if (driverToken != null) {
          await _sendNotificationToDriver(driverToken, rideId);
        }
      } else {
        final errorMessage =
            jsonDecode(response.body)['message'] ?? 'Failed to book ride';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $errorMessage')));
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error booking ride: $e')));
    }
  }

  Future<void> _sendNotificationToDriver(
    String driverToken,
    String rideId,
  ) async {
    const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';
        const String serverKey = "shidGdj08HHsb_jDhBCR";

    final body = {
      'to': driverToken,
      'notification': {
        'title': 'New Ride Booking',
        'body':
            'A passenger has booked your ride (ID: $rideId) at 06:20 PM today!',
      },
      'data': {'click_action': 'FLUTTER_NOTIFICATION_CLICK', 'rideId': rideId},
    };

    final response = await http.post(
      Uri.parse(fcmUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      print('Notification sent successfully');
    } else {
      print('Failed to send notification: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E2A),
        title: const Text(
          'Matching Rides',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      backgroundColor: const Color(0xFF0A0E2A),
      body:
          rides.isEmpty
              ? const Center(
                child: Text(
                  'No rides found',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: rides.length,
                itemBuilder: (context, index) {
                  final ride = rides[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16.0),
                      title: Text(
                        '${ride['startLocation']} to ${ride['endLocation']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Text('Date: ${ride['date']}'),
                          Text('Time: ${ride['time']}'),
                          Text('Distance: ${ride['route']['distance']}'),
                          Text('Duration: ${ride['route']['duration']}'),
                          Text('Status: ${ride['status']}'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => RideMapScreen(
                                            ride: ride,
                                            waypoint: waypoint,
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.map),
                                label: const Text('View on Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _bookRide(context, ride['rideId'], waypoint);
                                },
                                icon: const Icon(Icons.book),
                                label: const Text('Book'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
