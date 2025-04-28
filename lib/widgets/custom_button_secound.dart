import 'package:flutter/material.dart';

class CustomButtonSecoundary extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;
  final double width;
  final double height;
  final double borderRadius;
  final EdgeInsets padding;
  final FontWeight fontWeight;
  final double fontSize;
  final bool hasBorder;
  final Color borderColor;
  final double borderWidth;

  const CustomButtonSecoundary({
    Key? key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = Colors.blue,
    this.textColor = Colors.white,
    this.width = double.infinity,
    this.height = 50.0,
    this.borderRadius = 8.0,
    this.padding = const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
    this.fontWeight = FontWeight.bold,
    this.fontSize = 16.0,
    this.hasBorder = false,
    this.borderColor = Colors.grey,
    this.borderWidth = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: hasBorder ? Border.all(
          color: borderColor,
          width: borderWidth,
        ) : null,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          side: hasBorder ? BorderSide(
            color: borderColor,
            width: borderWidth,
          ) : BorderSide.none,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: textColor,
            fontWeight: fontWeight,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }
}


//example button 
// CustomButtonSecoundary(
//             text: "Back to Login",
//             backgroundColor: Colors.white,
//             textColor: Colors.black,
//             hasBorder: true,
//             borderColor: Colors.blue,
//             borderWidth: 1.5,
//             onPressed: () {
//               Navigator.pop(context);
//             },
//             width: 300,
//           ),
//             CustomButtonSecoundary(
//             text: "Delete Account",
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//             width: 200,
//             height: 45,
//             onPressed: () {
//               // Your action here
//             },
//           ),