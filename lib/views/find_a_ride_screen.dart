import 'package:flutter/material.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';

class FindARideScreen extends StatefulWidget {
  const FindARideScreen({Key? key}) : super(key: key);

  @override
  State<FindARideScreen> createState() => _FindARideScreenState();
}

class _FindARideScreenState extends State<FindARideScreen> {
  String? selectedTime;
  final TextEditingController pickUpController = TextEditingController();
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Form key for validation

  // Generate times like 00:00:00, 00:15:00, 00:30:00, ..., 23:45:00
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
    // Dispose controllers to release resources
    pickUpController.dispose();
    dropOffController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E2A),
      body: SafeArea(
        child: Form( // Wrap the form elements inside a Form widget
          key: _formKey, // Assign the form key for validation
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back arrow and title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded( // This ensures the text is centered
                      child: const Text(
                        'Find a Ride',
                        textAlign: TextAlign.center, // This centers the text
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Small Card: Ride Information Title
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(20),
                              topRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ride Information',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center, // Center the line
                                children: [
                                  Container(
                                    height: 2,
                                    width: 60,
                                    color: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Big Card: Form Fields
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0x9C002B5B)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: pickUpController,
                                      label: 'Pick-Up',
                                      hintText: 'Your Location',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, color: Color(0x9C002B5B)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: dropOffController,
                                      label: 'Drop-Off',
                                      hintText: 'Destination',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  const Icon(Icons.calendar_today, color: Color(0x9C002B5B)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomInputField(
                                      controller: dateController,
                                      label: 'Date',
                                      hintText: 'DD/MM/YYYY',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Time Dropdown
                              Row(
                                children: [
                                  const Icon(Icons.access_time, color: Color(0x9C002B5B)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomDropdownField(
                                      label: 'Time',
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

                              const SizedBox(height: 40),

                              // Search Ride Button
                              CustomButton(
                                text: 'Search Ride',
                                onPressed: () {
                                  // Validate the form data
                                  if (_formKey.currentState?.validate() ?? false) {
                                    // Proceed with the logic if form is valid
                                    print('Searching ride...');
                                    print('Pick-Up: ${pickUpController.text}');
                                    print('Drop-Off: ${dropOffController.text}');
                                    print('Date: ${dateController.text}');
                                    print('Time selected: $selectedTime');
                                    // Here you would typically trigger the ride search action
                                  } else {
                                    // Form is not valid, show error messages
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
