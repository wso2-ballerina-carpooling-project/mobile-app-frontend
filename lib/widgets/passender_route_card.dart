import 'package:flutter/material.dart';
import 'package:mobile_frontend/views/passenger/passenger_ride_tracking.dart';

class RouteCardPassenger extends StatefulWidget {
  final String startLocation;
  final String startAddress;
  final String endLocation;
  final String endAddress;
  final String date;
  final String time;
  final bool isRideStarted;
  final bool isGoingToWork;
  final Function()? onTrackPressed;

  const RouteCardPassenger({
    super.key,
    required this.startLocation,
    required this.startAddress,
    required this.endLocation,
    required this.endAddress,
    required this.date,
    required this.time,
    this.isRideStarted = true,
    this.isGoingToWork = true,
    this.onTrackPressed,
  });

  @override
  State<RouteCardPassenger> createState() => _RouteCardPassengerState();
}

class _RouteCardPassengerState extends State<RouteCardPassenger>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // Start blinking animation only when ride is started
    if (widget.isRideStarted) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(RouteCardPassenger oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update animation based on ride status
    if (widget.isRideStarted && !oldWidget.isRideStarted) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isRideStarted && oldWidget.isRideStarted) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleCardTap() {
    if (widget.isRideStarted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) {
          return const PassengerRideTracking();
        },
      );
      if (widget.onTrackPressed != null) {
        widget.onTrackPressed!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFFF9FAFB); // Light gray background for a clean look
    const primaryColor = Color(0xFF1E40AF); // Professional blue
    const infoBgColor = Color(0xFFE0E7FF); // Soft blue for info chips
    const textColor = Colors.black87; // Darker text for readability

    return GestureDetector(
      onTap: _handleCardTap,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                if (widget.isRideStarted)
                  BoxShadow(
                    color: primaryColor.withOpacity(_animation.value * 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
              ],
              border: widget.isRideStarted
                  ? Border.all(
                      color: primaryColor.withOpacity(_animation.value),
                      width: 2,
                    )
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Date and time on the left
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: infoBgColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.date,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                          Text(
                            " | " + widget.time,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Back to Work/Home on the right
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: infoBgColor,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.isGoingToWork ? 'Back to Work' : 'Back to Home',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.startLocation,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.endAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withOpacity(0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (widget.isRideStarted)
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.radio_button_checked,
                          color: primaryColor.withOpacity(_animation.value),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to track your ride',
                          style: TextStyle(
                            color: primaryColor.withOpacity(_animation.value),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Center(
                    child: Text(
                      'Driver not started ride yet',
                      style: TextStyle(
                        color: textColor.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}