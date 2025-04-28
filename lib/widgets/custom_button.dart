import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color textColor;
  final Color backgroundColor;
  final double height;
  final double? width;
  final EdgeInsets padding;

  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.textColor = Colors.white,
    this.backgroundColor = mainButtonColor,
    this.height = 70.0,
    this.width,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(10),
            topRight: Radius.zero, // No radius on top-right
            bottomRight: Radius.circular(10),
            bottomLeft: Radius.circular(10),
            // bottomLeft has no radius to match your example
          ),
          child: Ink(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10), 
                bottomRight: Radius.circular(10),
                bottomLeft: Radius.circular(10),
              ),
            ),
            child: Center(
              child: Padding(
                padding: padding,
                child: Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w400, // Thinner text weight
                    letterSpacing:
                        0.5, // Slight letter spacing for a thinner appearance
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
