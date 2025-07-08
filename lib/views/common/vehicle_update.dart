import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'package:mobile_frontend/config/constant.dart';
import 'package:mobile_frontend/services/profile_service.dart';
import 'package:mobile_frontend/widgets/custom_input_field.dart';
import 'package:mobile_frontend/widgets/custom_button.dart';
import 'package:mobile_frontend/widgets/dropdown_input.dart';

class VehicleUpdate extends StatefulWidget {
  const VehicleUpdate({Key? key}) : super(key: key);

  @override
  State<VehicleUpdate> createState() => _VehicleUpdateState();
}

class _VehicleUpdateState extends State<VehicleUpdate> {
  late TextEditingController _vehicleModelController;
  late TextEditingController _vehicleRegistrationController;
  String? _vehicleTypeValue;
  String? _vehicleBrandValue;
  int _numberOfSeats = 2;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _vehicleModelController = TextEditingController();
    _vehicleRegistrationController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadVehicleData();
  }

  Future<void> _loadVehicleData() async {
    try {
      final token = await _storage.read(key: 'jwt_token') ?? '';
      final payload = Jwt.parseJwt(token);
      final vehicleDetails = payload['driverDetails'] as Map<String, dynamic>? ?? {};
      if (_vehicleTypeValue != (vehicleDetails['vehicleType'] as String?) ||
          _vehicleBrandValue != (vehicleDetails['vehicleBrand'] as String?) ||
          _vehicleModelController.text != (vehicleDetails['vehicleModel'] as String? ?? '') ||
          _vehicleRegistrationController.text != (vehicleDetails['vehicleRegistrationNumber'] as String? ?? '') ||
          _numberOfSeats != (vehicleDetails['seatingCapacity'] as int? ?? 2)) {
        setState(() {
          _vehicleTypeValue = vehicleDetails['vehicleType'] as String?;
          _vehicleBrandValue = vehicleDetails['vehicleBrand'] as String?;
          _vehicleModelController.text = vehicleDetails['vehicleModel'] as String? ?? '';
          _vehicleRegistrationController.text = vehicleDetails['vehicleRegistrationNumber'] as String? ?? '';
          _numberOfSeats = vehicleDetails['seatingCapacity'] as int? ?? 2;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading vehicle data: $e')),
      );
    }
  }

  @override
  void dispose() {
    _vehicleModelController.dispose();
    _vehicleRegistrationController.dispose();
    super.dispose();
  }

  Future<void> _updateVehicle() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      try {
        final token = await _storage.read(key: 'jwt_token') ?? '';
        final vehicleData = {
            'vehicleType': _vehicleTypeValue,
            'vehicleBrand': _vehicleBrandValue,
            'vehicleModel': _vehicleModelController.text,
            'vehicleRegistrationNumber': _vehicleRegistrationController.text,
            'seatingCapacity': _numberOfSeats,
        };

        final response = await ProfileService.editVehicle(vehicleData, token);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vehicle updated successfully!')),
          );
          final newToken = response.headers['authorization']?.replaceFirst('Bearer ', '') ?? token;
          if (newToken != token) {
            await _storage.write(key: 'jwt_token', value: newToken);
          }
          final updatedVehicle = {
            'vehicleType': _vehicleTypeValue,
            'vehicleBrand': _vehicleBrandValue,
            'vehicleModel': _vehicleModelController.text,
            'vehicleRegistrationNumber': _vehicleRegistrationController.text,
            'seatingCapacity': _numberOfSeats,
          };
          Navigator.pop(context, updatedVehicle);
        } else {
          throw Exception('Failed to update vehicle: ${response.body}');
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update vehicle: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
                        ),
                      ),
                      const Text(
                        'Vehicle',
                        style: TextStyle(
                          fontSize: 30,
                          color: Colors.white,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 20),
                            CustomDropdownField(
                              label: 'Vehicle Type',
                              options: ['Sedan', 'SUV', 'Hatchback', 'Van', 'Bus', 'Truck'],
                              value: _vehicleTypeValue,
                              hintText: 'Select vehicle type',
                              onChanged: (value) {
                                setState(() {
                                  _vehicleTypeValue = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            CustomDropdownField(
                              label: 'Vehicle Brand',
                              options: ['Toyota', 'Honda', 'Nissan', 'Ford', 'BMW', 'Mercedes', 'Audi'],
                              value: _vehicleBrandValue,
                              hintText: 'Select vehicle brand',
                              onChanged: (value) {
                                setState(() {
                                  _vehicleBrandValue = value;
                                });
                              },
                            ),
                            const SizedBox(height: 10),
                            CustomInputField(
                              label: 'Vehicle Model',
                              controller: _vehicleModelController,
                              hintText: 'Camry',
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter vehicle model';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 10),
                            CustomInputField(
                              label: 'Vehicle Registration Number',
                              controller: _vehicleRegistrationController,
                              hintText: 'ABC-1234',
                              keyboardType: TextInputType.text,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter registration number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'No. of seats available',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 60,
                                        height: 45,
                                        alignment: Alignment.center,
                                        child: Text(
                                          _numberOfSeats.toString(),
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (_numberOfSeats < 10) _numberOfSeats++;
                                              });
                                            },
                                            child: Container(
                                              width: 28,
                                              height: 22.5,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(color: Colors.grey.shade300),
                                                  bottom: BorderSide(color: Colors.grey.shade300),
                                                ),
                                              ),
                                              child: const Icon(Icons.add, size: 16),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              setState(() {
                                                if (_numberOfSeats > 1) _numberOfSeats--;
                                              });
                                            },
                                            child: Container(
                                              width: 28,
                                              height: 22.5,
                                              decoration: BoxDecoration(
                                                border: Border(
                                                  left: BorderSide(color: Colors.grey.shade300),
                                                ),
                                              ),
                                              child: const Icon(Icons.remove, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 30),
                            CustomButton(
                              text: 'Save',
                              backgroundColor: mainButtonColor,
                              height: 60,
                              onPressed: _updateVehicle,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}