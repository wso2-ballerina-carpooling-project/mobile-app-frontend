import 'package:flutter/material.dart';

class CustomInputFieldSecoundary extends StatelessWidget {
  final String label; // Keeping this parameter for backward compatibility
  final TextEditingController? controller;
  final bool isPassword;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final String? hintText;
  final Widget? suffixIcon;
  final Function(String)? onChanged;

  const CustomInputFieldSecoundary({
    Key? key,
    required this.label,
    this.controller,
    this.isPassword = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.suffixIcon,
    this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.6),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: TextFormField(
          controller: controller,
          obscureText: isPassword,
          validator: validator,
          keyboardType: keyboardType,
          onChanged: onChanged,
          textAlign: TextAlign.center, // Center the text
          style: const TextStyle(fontSize: 18),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500]),
            border: InputBorder.none,
            suffixIcon: suffixIcon,
            contentPadding: EdgeInsets.zero,
            isDense: true,
          ),
        ),
      ),
    );
  }
}

// example 
//  CustomInputFieldSecoundary(
//               label: 'Name', // This won't be displayed but is still required
//               controller: _nameController,
//               hintText: 'Enter your full name',
//               keyboardType: TextInputType.name,
//               validator: (value) {
//                 if (value == null || value.isEmpty) {
//                   return 'Please enter your name';
//                 }
//                 return null;
//               },
//             ),