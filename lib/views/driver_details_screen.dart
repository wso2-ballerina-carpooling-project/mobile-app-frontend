import 'package:flutter/material.dart';
import 'sign_up_pending_screen.dart';

class DriverDetailsScreen extends StatefulWidget {
  const DriverDetailsScreen({super.key});

  @override
  _DriverDetailsScreenState createState() => _DriverDetailsScreenState();
}

class _DriverDetailsScreenState extends State<DriverDetailsScreen> {
  String? selectedVehicleType;
  String? selectedVehicleBrand;
  TextEditingController modelController = TextEditingController();
  TextEditingController regNumberController = TextEditingController();
  int seatCount = 1;

  final List<String> vehicleTypes = ['Car', 'Van', 'Bike', 'Bus'];
  final List<String> vehicleBrands = ['Toyota', 'Nissan', 'Honda', 'Suzuki'];

  void increaseSeats() => setState(() => seatCount++);
  void decreaseSeats() => setState(() {
        if (seatCount > 1) seatCount--;
      });

  void completeRegistration() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SignUpPendingScreen(),
      ),
    );
  }

  Widget buildDropdown(String label, List<String> items, String? selectedItem,
      void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedItem,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      items: items
          .map((item) => DropdownMenuItem<String>(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Custom-shaped white container aligned to the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
              ),
              child: Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          "Complete Your Registration",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      buildDropdown("Vehicle Type", vehicleTypes,
                          selectedVehicleType, (val) {
                        setState(() => selectedVehicleType = val);
                      }),
                      const SizedBox(height: 15),
                      buildDropdown("Vehicle Brand", vehicleBrands,
                          selectedVehicleBrand, (val) {
                        setState(() => selectedVehicleBrand = val);
                      }),
                      const SizedBox(height: 15),
                      TextField(
                        controller: modelController,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Model',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: regNumberController,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Registration Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          Text("No. of seats available", style: TextStyle(fontSize: 16)),
                          Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.black),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: decreaseSeats,
                                  icon: Icon(Icons.remove),
                                ),
                                Text('$seatCount'),
                                IconButton(
                                  onPressed: increaseSeats,
                                  icon: Icon(Icons.add),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: completeRegistration,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            "Complete Registration",
                            style: TextStyle(
                              color: Colors.white, 
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
