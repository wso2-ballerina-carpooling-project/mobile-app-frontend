import 'package:flutter/material.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({super.key});

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  final TextEditingController _vehicleTypeController = TextEditingController(text: 'Car');
  final TextEditingController _vehicleBrandController = TextEditingController(text: 'Honda');
  final TextEditingController _vehicleModelController = TextEditingController(text: 'Civic');
  final TextEditingController _registrationController = TextEditingController(text: 'CBL-8090');
  final TextEditingController _seatsController = TextEditingController(text: '2');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1234), // Dark navy blue
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1234),
        elevation: 0,
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Vehicle Details",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CustomInputField(
                label: "Vehicle Type",
                controller: _vehicleTypeController,
                hintText: "Enter vehicle type",
              ),
              CustomInputField(
                label: "Vehicle Brand",
                controller: _vehicleBrandController,
                hintText: "Enter vehicle brand",
              ),
              CustomInputField(
                label: "Vehicle Model",
                controller: _vehicleModelController,
                hintText: "Enter vehicle model",
              ),
              CustomInputField(
                label: "Vehicle Registration Number",
                controller: _registrationController,
                hintText: "Enter registration number",
              ),
              CustomInputField(
                label: "No. of seats available",
                controller: _seatsController,
                keyboardType: TextInputType.number,
                hintText: "Enter number of seats",
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: "Cancel",
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      backgroundColor: Colors.white,
                      textColor: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: "Save",
                      onPressed: () {
                        // Save action
                      },
                      backgroundColor: Colors.green,
                      textColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
