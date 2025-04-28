import 'package:flutter/material.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';

class RidePostScreen extends StatefulWidget {
  const RidePostScreen({Key? key}) : super(key: key);

  @override
  State<RidePostScreen> createState() => _RidePostScreenState();
}

class _RidePostScreenState extends State<RidePostScreen> {
  String? selectedTime;
  String? selectedReturnTime;
  bool isVehicleRegEditable = false;
  final TextEditingController pickUpController = TextEditingController();
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController vehicleRegController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> generateTimes() {
    List<String> times = [];
    for (int hour = 0; hour < 24; hour++) {
      for (int minute = 0; minute < 60; minute += 15) {
        final hh = hour.toString().padLeft(2, '0');
        final mm = minute.toString().padLeft(2, '0');
        times.add('$hh:$mm:00');
      }
    }
    return times;
  }

  @override
  void dispose() {
    pickUpController.dispose();
    dropOffController.dispose();
    dateController.dispose();
    vehicleRegController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: const Text(
                        'Post a Ride',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Body
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title Card
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ride Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Container(
                                  height: 2,
                                  width: 50,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: [
                              // Starting point
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0x9C002B5B), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: pickUpController,
                                      label: 'Starting-Point',
                                      hintText: 'Your Location',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // End point
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Color(0x9C002B5B), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: dropOffController,
                                      label: 'End-Point',
                                      hintText: 'Destination',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Date
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0x9C002B5B), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: dateController,
                                      label: 'Date',
                                      hintText: 'DD/MM/YYYY',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Start Time
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0x9C002B5B), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomDropdownField(
                                      label: 'Arriving Time/Start Time',
                                      hintText: '08:00:00',
                                      options: generateTimes(),
                                      value: selectedTime,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedTime = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Return Time
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0x9C002B5B), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: CustomDropdownField(
                                      label: 'Trip Start Time',
                                      hintText: '07:00:00',
                                      options: generateTimes(),
                                      value: selectedReturnTime,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedReturnTime = value;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Vehicle Registration Number
                              Row(
                                children: [
                                  const Icon(Icons.directions_car, color: Color(0x9C002B5B), size: 50),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextFormField(
                                      controller: vehicleRegController,
                                      enabled: isVehicleRegEditable,
                                      decoration: const InputDecoration(
                                        labelText: 'CBL 5680',
                                        hintText: 'Vehicle Reg. No.',
                                        border: InputBorder.none,
                                        filled: true,
                                        fillColor: Color(0xFFF2F2F2),
                                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical:8),
                                      ),
                                      style: const TextStyle(color: Colors.black),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Color(0xFF0A0E2A)),
                                    onPressed: () {
                                      setState(() {
                                        isVehicleRegEditable = true;
                                      });
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Post Ride Button
                              CustomButton(
                                text: 'Post Ride',
                                onPressed: () {
                                  if (_formKey.currentState?.validate() ?? false) {
                                    print('Posting ride...');
                                    print('Pick-Up: ${pickUpController.text}');
                                    print('Drop-Off: ${dropOffController.text}');
                                    print('Date: ${dateController.text}');
                                    print('Time selected: $selectedTime');
                                    print('Return Time: $selectedReturnTime');
                                    print('Vehicle Reg: ${vehicleRegController.text}');
                                  } else {
                                    print('Please fill in all required fields.');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
