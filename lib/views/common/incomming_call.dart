import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class IncomingCallScreen extends StatefulWidget {
  final String token;
  final String channelName;
  final int uid;
  final String? contactName;
  final String? contactImage;
  final String? contactNumber;

  const IncomingCallScreen({
    Key? key,
    required this.token,
    required this.channelName,
    required this.uid,
    this.contactName,
    this.contactImage,
    this.contactNumber,
  }) : super(key: key);

  @override
  _IncomingCallScreenState createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late AnimationController _backgroundController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _backgroundAnimation;

  Timer? _callTimeoutTimer;
  bool _isAnswering = false;
  bool _isDeclining = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startCallTimeout();
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _backgroundController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_backgroundController);

    _slideController.forward();
  }

  void _startCallTimeout() {
    _callTimeoutTimer = Timer(const Duration(seconds: 30), () {
      if (mounted) {
        _declineCall(auto: true);
      }
    });
  }

  void _acceptCall() async {
    if (_isAnswering || _isDeclining) return;

    setState(() {
      _isAnswering = true;
    });

    HapticFeedback.mediumImpact();
    _callTimeoutTimer?.cancel();

    // Show accepting animation briefly
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        '/call',
        arguments: {
          'token': widget.token,
          'channelName': widget.channelName,
          'uid': widget.uid,
          'contactName': widget.contactName,
        },
      );
    }
  }

  void _declineCall({bool auto = false}) async {
    if (_isAnswering || _isDeclining) return;

    setState(() {
      _isDeclining = true;
    });

    if (!auto) {
      HapticFeedback.heavyImpact();
    }
    _callTimeoutTimer?.cancel();

    // Show declining animation briefly
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      Navigator.pop(context, false);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    _backgroundController.dispose();
    _callTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF1a1a2e),
              const Color(0xFF16213e),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Stack(
          children: [
            _buildAnimatedBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildMainContent()),
                  _buildCallActions(),
                ],
              ),
            ),
            if (_isAnswering) _buildAnsweringOverlay(),
            if (_isDeclining) _buildDecliningOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _backgroundAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.0 + (0.5 * _backgroundAnimation.value),
              colors: [
                Colors.blue.withOpacity(0.1),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Incoming call',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Audio Call',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildCallerAvatar(),
          const SizedBox(height: 40),
          _buildCallerInfo(),
          const SizedBox(height: 20),
          _buildCallStatus(),
        ],
      ),
    );
  }

  Widget _buildCallerAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer pulse ring
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 200 * _pulseAnimation.value,
              height: 200 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
              ),
            );
          },
        ),
        // Middle pulse ring
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: 160 * _pulseAnimation.value,
              height: 160 * _pulseAnimation.value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
              ),
            );
          },
        ),
        // Main avatar
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[300]!,
                Colors.blue[600]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: widget.contactImage != null && widget.contactImage!.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    widget.contactImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildDefaultAvatar(),
                  ),
                )
              : _buildDefaultAvatar(),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 70,
      color: Colors.white,
    );
  }

  Widget _buildCallerInfo() {
    return Column(
      children: [
        Text(
          widget.contactName ?? 'Unknown Caller',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),
        if (widget.contactNumber != null) ...[
          const SizedBox(height: 8),
          Text(
            widget.contactNumber!,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 18,
              fontWeight: FontWeight.w400,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildCallStatus() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (0.5 * _pulseAnimation.value),
          child: Text(
            'Incoming audio call...',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCallActions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.call_end,
            color: Colors.red,
            onTap: () => _declineCall(),
            isActive: _isDeclining,
          ),
          const SizedBox(width: 80),
          _buildActionButton(
            icon: Icons.call,
            color: Colors.green,
            onTap: _acceptCall,
            isActive: _isAnswering,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: isActive ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? color.withOpacity(0.8) : color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: isActive ? 8 : 3,
            ),
          ],
        ),
        child: isActive
            ? const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                ),
              )
            : Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
      ),
    );
  }

  Widget _buildAnsweringOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.green.withOpacity(0.2),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.call,
              color: Colors.green,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              'Connecting...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecliningOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.red.withOpacity(0.2),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.call_end,
              color: Colors.red,
              size: 60,
            ),
            SizedBox(height: 20),
            Text(
              'Declining...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}