import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/ride_post_confirmation.dart';
import 'package:mobile_frontend/views/map_sample.dart';
import '../widgets/custom_button.dart'; // Import the CustomButton widget

class RideSelectionPage extends StatelessWidget {
  const RideSelectionPage({Key? key}) : super(key: key);

  void _openMap(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MapSample()), // Navigate to MapSample page
    );
  }

  void _goToConfirmationPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RidePostConfirmationPage()), // Navigate to Confirmation page
    );
  }

  Widget _buildRideCard(BuildContext context, IconData vehicleIcon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 12), // Increased margin for larger box
      child: Padding(
        padding: const EdgeInsets.all(16), // Increased padding for larger box
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Text and details on the left
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Taylor Morgan',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const Text('Honda Civic', style: TextStyle(fontSize: 14)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[300], // Grey background for "2/4 seats"
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('2/4 seats', style: TextStyle(fontSize: 12)),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _openMap(context),
                            child: const Text(
                              'View route',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF4747E7),
                                
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Vehicle icon on the right
                Icon(vehicleIcon, size: 100), // Increased icon size
              ],
            ),
            const SizedBox(height: 16),
            // Buttons at the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Custom Button for "Book"
                CustomButton(
                  text: 'Book',
                  backgroundColor: Color(0xFF4A5EAA),
                  textColor: Colors.white,
                  height: 40.0,
                  width: 75.0,
                  onPressed: () => _goToConfirmationPage(context),
                ),
                // Custom Button for "More Details"
                CustomButton(
                  text: 'More Details',
                  backgroundColor: Color(0xFF4EB665),
                  textColor: Colors.white,
                  height: 40.0,
                  width: 150.0,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('More details coming soon!')),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
       // Get the current date and time
    final DateTime now = DateTime.now();
    final String currentDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final String currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
    return Scaffold(
      backgroundColor: Colors.indigo[900],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          'WSO2',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Text(
              '$currentDate - $currentTime',//update to show current date and time
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 5),
            const Text(
              'Rs. 240.45',
              style: TextStyle(color: Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  _buildRideCard(context, Icons.directions_car),
                  _buildRideCard(context, Icons.directions_car),
                  _buildRideCard(context, Icons.airport_shuttle),
                  _buildRideCard(context, Icons.directions_car),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}