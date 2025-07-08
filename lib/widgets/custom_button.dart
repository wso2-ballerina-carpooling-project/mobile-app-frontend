import 'package:flutter/material.dart';
import 'package:mobile_frontend/config/constant.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color backgroundColor;
  final double height;
  final double? width;
  final EdgeInsets padding;
  final bool useGradient;
  final List<Color>? gradientColors;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.textColor = Colors.white,
    this.backgroundColor = mainButtonColor,
    this.height = 70.0,
    this.width = 400,
    this.padding = const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
    this.useGradient = false,
    this.gradientColors,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              gradient: widget.useGradient && !isDisabled
                  ? LinearGradient(
                      colors: widget.gradientColors ??
                          [widget.backgroundColor, primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isDisabled ? widget.backgroundColor.withOpacity(0.5) : widget.backgroundColor,
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(_isPressed ? 0.4 : 0.2),
                  spreadRadius: 1,
                  blurRadius: 6,
                  offset: Offset(0, _isPressed ? 3 : 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: widget.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: widget.textColor,
                shadowColor: Colors.transparent,
                padding: widget.padding,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                disabledBackgroundColor: Colors.transparent,
                disabledForegroundColor: widget.textColor.withOpacity(0.5),
              ),
              onFocusChange: (hasFocus) {
                setState(() {
                  _isPressed = hasFocus;
                  if (hasFocus) {
                    _animationController.forward();
                  } else {
                    _animationController.reverse();
                  }
                });
              },
              child: Semantics(
                label: widget.text,
                button: true,
                enabled: !isDisabled,
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: isDisabled ? widget.textColor.withOpacity(0.5) : widget.textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}