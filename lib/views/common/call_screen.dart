import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:permission_handler/permission_handler.dart';

class CallingScreen extends StatefulWidget {
  final String callerName;
  final String callerPhone;
  final String passengerPhone;
  final String passengerName;
  final String userType;

  const CallingScreen({
    super.key,
    required this.callerName,
    required this.callerPhone,
    required this.passengerPhone,
    required this.passengerName,
    required this.userType,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  String _callStatus = 'Connecting...';
  bool _callInitiated = false;
  bool _isCallActive = false;
  bool _isSpeakerOn = false;
  bool _isMuted = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final String baseUrl = 'http://your-ngrok-url.ngrok.io';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _setupAnimations();
    // Auto-dial when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _makeCall();
    });
  }

  void _setupAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    _pulseController.repeat(reverse: true);
  }

  Future<void> _requestPermissions() async {
    await Permission.phone.request();
    await Permission.microphone.request();
  }

  Future<void> _makeCall() async {
    if (_callInitiated) return;
    
    setState(() {
      _isLoading = true;
      _callStatus = 'Connecting...';
      _callInitiated = true;
    });

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/calling/call'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'callerPhone': widget.callerPhone,
          'calleePhone': widget.passengerPhone,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _callStatus = 'Call connected';
          _isCallActive = true;
        });
      } else {
        setState(() {
          _callStatus = 'Call failed';
        });
      }
    } catch (_) {
      setState(() {
        _callStatus = 'Connection error';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _endCall() {
    setState(() {
      _isCallActive = false;
      _callStatus = 'Call ended';
    });
    _pulseController.stop();
    
    // Navigate back after a short delay
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
    });
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    _callStatus,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),
            
            const Spacer(),
            
            // Profile section
            Column(
              children: [
                // Profile picture with pulse animation
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _isCallActive ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 32),
                
                // Name
                Text(
                  widget.passengerName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Call status
                Text(
                  _callStatus,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                  ),
                ),
                
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
              ],
            ),
            
            const Spacer(),
            
            // Call controls
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Mute button
                  _buildCallButton(
                    icon: _isMuted ? Icons.mic_off : Icons.mic,
                    onPressed: _toggleMute,
                    backgroundColor: _isMuted ? Colors.white : Colors.grey[800]!,
                    iconColor: _isMuted ? Colors.grey[800]! : Colors.white,
                  ),
                  
                  // End call button
                  _buildCallButton(
                    icon: Icons.call_end,
                    onPressed: _endCall,
                    backgroundColor: Colors.red,
                    iconColor: Colors.white,
                    size: 70,
                  ),
                  
                  // Speaker button
                  _buildCallButton(
                    icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
                    onPressed: _toggleSpeaker,
                    backgroundColor: _isSpeakerOn ? Colors.white : Colors.grey[800]!,
                    iconColor: _isSpeakerOn ? Colors.grey[800]! : Colors.white,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCallButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color iconColor,
    double size = 60,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor),
        onPressed: onPressed,
        iconSize: size * 0.4,
      ),
    );
  }
}