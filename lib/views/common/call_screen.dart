import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class CallingScreen extends StatefulWidget {
  final String token;
  final String channelName;
  final int uid;
  final String? contactName; // Optional contact name
  final String? contactImage; // Optional contact image

  CallingScreen({
    required this.token,
    required this.channelName,
    required this.uid,
    this.contactName,
    this.contactImage,
  });

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> with TickerProviderStateMixin {
  late final RtcEngine _engine;
  bool _joined = false;
  bool _isMuted = false;
  bool _isSpeakerOn = false;
  int? _remoteUid;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  Timer? _callTimer;
  Duration _callDuration = Duration.zero;
  String _callStatus = 'Connecting...';
  bool _isCallActive = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initAgora();
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: '32f8dd6fbfad4a18986c278345678b41',
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          setState(() {
            _joined = true;
            _callStatus = 'Calling...';
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (_remoteUid == null) {
            setState(() {
              _remoteUid = remoteUid;
              _isCallActive = true;
              _startCallTimer();
            });
          }
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (_remoteUid == remoteUid) {
            _handleCallEnd('Call ended');
          }
        },
        onConnectionLost: (connection) {
          _handleCallEnd('Connection lost');
        },
        onError: (errorCode, message) {
          print('Agora error: $errorCode, message: $message');
          _showErrorSnackBar('Connection error occurred');
        },
      ),
    );

    await _engine.enableAudio();
    await _engine.setDefaultAudioRouteToSpeakerphone(false);
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(),
    );
  }

  void _handleCallEnd(String reason) {
    setState(() {
      _remoteUid = null;
      _isCallActive = false;
      _callStatus = reason;
    });
    _stopCallTimer();
    
    // Show end call dialog after a short delay
    Timer(const Duration(seconds: 1), () {
      _showCallEndDialog(reason);
    });
  }

  void _showCallEndDialog(String reason) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2C2C2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            reason,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          content: Text(
            _callDuration.inSeconds > 0 
                ? 'Call duration: ${_formatDuration(_callDuration)}'
                : 'The call couldn\'t be established',
            style: TextStyle(color: Colors.grey[300]),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  void _startCallTimer() {
    _callDuration = Duration.zero;
    _callTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDuration += const Duration(seconds: 1);
        _callStatus = _formatDuration(_callDuration);
      });
    });
  }

  void _stopCallTimer() {
    _callTimer?.cancel();
    _callTimer = null;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return hours == '00' ? '$minutes:$seconds' : '$hours:$minutes:$seconds';
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      _engine.muteLocalAudioStream(_isMuted);
    });
  }

  void _toggleSpeaker() {
    setState(() {
      _isSpeakerOn = !_isSpeakerOn;
      _engine.setDefaultAudioRouteToSpeakerphone(_isSpeakerOn);
    });
  }

  void _endCall() {
    _handleCallEnd('Call ended');
    _engine.leaveChannel();
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    _stopCallTimer();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_joined) {
      return Scaffold(
        backgroundColor: const Color(0xFF1C1C1E),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Connecting...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            _buildHeader(),
            // Main content
            Expanded(child: _buildMainContent()),
            // Call controls
            _buildCallControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Spacer(),
          Column(
            children: [
              Text(
                _isCallActive ? 'Connected' : _callStatus,
                style: TextStyle(
                  color: _isCallActive ? Colors.green : Colors.grey[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_isCallActive)
                Text(
                  _callStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          const Spacer(),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildContactAvatar(),
          const SizedBox(height: 32),
          _buildContactInfo(),
          const SizedBox(height: 16),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildContactAvatar() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ripple effect for calling state
        if (!_isCallActive) ...[
          AnimatedBuilder(
            animation: _rippleController,
            builder: (context, child) {
              return Container(
                width: 200 + (100 * _rippleController.value),
                height: 200 + (100 * _rippleController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.blue.withOpacity(1 - _rippleController.value),
                    width: 2,
                  ),
                ),
              );
            },
          ),
        ],
        // Main avatar
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[400]!,
                Colors.blue[600]!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: widget.contactImage != null
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
        // Pulse animation for active call
        if (_isCallActive)
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                width: 160 + (20 * _pulseController.value),
                height: 160 + (20 * _pulseController.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.green.withOpacity(0.5 - (_pulseController.value * 0.5)),
                    width: 3,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return const Icon(
      Icons.person,
      size: 80,
      color: Colors.white,
    );
  }

  Widget _buildContactInfo() {
    return Column(
      children: [
        Text(
          widget.contactName ?? 'Contact',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        
      ],
    );
  }

  Widget _buildStatusIndicator() {
    if (!_isCallActive) {
      return FadeTransition(
        opacity: _pulseController,
        child: Text(
          'Connecting...',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    return Container();
  }

  Widget _buildCallControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            isActive: !_isMuted,
            onTap: _toggleMute,
            backgroundColor: _isMuted ? Colors.red : const Color(0xFF2C2C2E),
          ),
          _buildControlButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.volume_down,
            isActive: _isSpeakerOn,
            onTap: _toggleSpeaker,
            backgroundColor: const Color(0xFF2C2C2E),
          ),
          _buildControlButton(
            icon: Icons.call_end,
            isActive: false,
            onTap: _endCall,
            backgroundColor: Colors.red,
            size: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
    double size = 64,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? const Color(0xFF2C2C2E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(size / 2),
          onTap: onTap,
          child: Icon(
            icon,
            color: Colors.white,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}