import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final String? hint; // Optional placeholder text
  final bool obscureText;

  const CustomInputField({
    super.key,
    required this.label,
    this.hint,
    this.obscureText = false,
  });


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 5),

        // TextField
        TextField(
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint, // Optional placeholder text
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), // Rounded corners
              borderSide: BorderSide.none, // No border
            ),
          ),
        ),
      ],
    );
  }
}
