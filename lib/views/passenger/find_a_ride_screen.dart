import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../select_location.dart';

class FindARideScreen extends StatefulWidget {
  const FindARideScreen({Key? key}) : super(key: key);

  @override
  State<FindARideScreen> createState() => _FindARideScreenState();
}

class _FindARideScreenState extends State<FindARideScreen> {
  static const LatLng wso2Location = LatLng(
    6.896169826136759,
    79.85657776071614,
  );
  static const String wso2Address = "WSO2 Office";

  String? selectedTime;
  final TextEditingController pickUpController = TextEditingController();
  final TextEditingController dropOffController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  LatLng? selectedPickupLocation;
  LatLng? selectedDropoffLocation;

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

  Future<void> _selectLocation(BuildContext context, bool isPickup) async {
    final selectedLocation = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder:
            (context) => SelectLocation(
              initialLocation:
                  isPickup ? selectedPickupLocation : selectedDropoffLocation,
            ),
      ),
    );

    if (selectedLocation != null) {
      setState(() {
        if (isPickup) {
          selectedPickupLocation = selectedLocation;
          pickUpController.text =
              _isWSO2Location(selectedLocation)
                  ? wso2Address
                  : "Selected Location";
        } else {
          selectedDropoffLocation = selectedLocation;
          dropOffController.text =
              _isWSO2Location(selectedLocation)
                  ? wso2Address
                  : "Selected Location";
        }
      });
    }
  }

  bool _isWSO2Location(LatLng location) {
    // Simple distance check - in a real app you might want a more precise check
    return (location.latitude - wso2Location.latitude).abs() < 0.0001 &&
        (location.longitude - wso2Location.longitude).abs() < 0.0001;
  }

  @override
  void dispose() {
    pickUpController.dispose();
    dropOffController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                  top:60,
                  bottom: 30,
                  left: 16,
                  right: 16
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Find a Ride',
                        textAlign: TextAlign.center,
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
                        Container(
                          width: MediaQuery.of(context).size.width * 0.6,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                              // Pick-Up Field
                              GestureDetector(
                                onTap: () => _selectLocation(context, true),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      color: Color(0x9C002B5B),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AbsorbPointer(
                                        child: CustomInputField(
                                          controller: pickUpController,
                                          label: 'Pick-Up',
                                          hintText: 'Tap to select location',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Drop-Off Field
                              GestureDetector(
                                onTap: () => _selectLocation(context, false),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on_outlined,
                                      color: Color(0x9C002B5B),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: AbsorbPointer(
                                        child: CustomInputField(
                                          controller: dropOffController,
                                          label: 'Drop-Off',
                                          hintText: 'Tap to select location',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0x9C002B5B),
                                  ),
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
                                  const Icon(
                                    Icons.access_time,
                                    color: Color(0x9C002B5B),
                                  ),
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
                                  if (_formKey.currentState?.validate() ??
                                      false) {
                                    // Check if one of the locations is WSO2
                                    final isPickupWSO2 =
                                        selectedPickupLocation != null &&
                                        _isWSO2Location(
                                          selectedPickupLocation!,
                                        );
                                    final isDropoffWSO2 =
                                        selectedDropoffLocation != null &&
                                        _isWSO2Location(
                                          selectedDropoffLocation!,
                                        );

                                    if (!isPickupWSO2 && !isDropoffWSO2) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'One of the locations must be WSO2 Office',
                                          ),
                                        ),
                                      );
                                      return;
                                    }

                                    // Proceed with ride search
                                    print('Searching ride...');
                                    print('Pick-Up: ${pickUpController.text}');
                                    print(
                                      'Drop-Off: ${dropOffController.text}',
                                    );
                                    print('Date: ${dateController.text}');
                                    print('Time selected: $selectedTime');
                                  } else {
                                    print(
                                      'Please fill in all required fields.',
                                    );
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
