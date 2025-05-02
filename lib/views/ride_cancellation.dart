import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_input_field.dart';

class RideCancellationPage extends StatefulWidget {
  const RideCancellationPage({super.key});

  @override
  State<RideCancellationPage> createState() => _RideCancellationPageState();
}

class _RideCancellationPageState extends State<RideCancellationPage> {
  final TextEditingController _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  void _submitCancellation() {
    final reason = _reasonController.text.trim();
    if (reason.isNotEmpty) {
      // logic here
      print('Cancellation Reason: $reason');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cancellation reason submitted')));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please provide a reason')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A23),
        foregroundColor: Colors.white,
        title: const Text('Ride Cancellation'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInputField(
              label: 'Oops! Cancelling? Tell us why',
              controller: _reasonController,
              hintText: 'Type your reason here...',
              keyboardType: TextInputType.multiline,
            ),
            const SizedBox(height: 20),
            Center(
              child: CustomButton(
                text: 'Submit',
                onPressed: _submitCancellation,
                backgroundColor: const Color.fromARGB(255, 106, 52, 168), // Green submit
                textColor: Colors.white,
                height: 50,
                width: 120,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
