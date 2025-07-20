import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/call_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  bool _isJoined = false;
  bool _isLoading = true;
  String? _callId;
  String _callerName = 'Unknown';
  String? _channelName;
  String? _token;
  String _errorMessage = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isLoading) {
      _joinCall();
    }
  }

  Future<void> _joinCall() async {
    print('Starting _joinCall');
    try {
      final args = ModalRoute.of(context)!.settings.arguments as Map;
      print('Received arguments: $args');
      _callId = args['callId'] as String?;
      _channelName = args['channelName'] as String?;
      _callerName = args['callerName'] as String? ?? args['callerId'] as String? ?? 'Unknown';
      _token = args['token'] as String?;

      if (_callId == null || _channelName == null || _token == null) {
        print('Missing callId, channelName, or token. Fetching call details...');
        final callDetails = await _callService.getCallDetails(_callId!);
        setState(() {
          _callerName = callDetails['callerName'] ?? callDetails['callerId'] ?? 'Unknown';
          _channelName = callDetails['channelName'];
          _token = callDetails['token'];
        });
      }

      // Check microphone permission
      var status = await Permission.microphone.status;
      print('Microphone permission status: $status');
      if (!status.isGranted) {
        status = await Permission.microphone.request();
        if (!status.isGranted) {
          throw Exception('Microphone permission denied');
        }
      }

      if (_channelName != null && _token != null) {
        print('Calling initAgora with channel: $_channelName, token: $_token');
        await _callService.initAgora(_channelName!, _token!);
        setState(() {
          _isJoined = true;
          _isLoading = false;
        });
        print('Successfully joined call');
      } else {
        throw Exception('Channel name or token not found');
      }
    } catch (e, stackTrace) {
      print('Error joining call: $e\nStackTrace: $stackTrace');
      setState(() {
        _errorMessage = e.toString().contains('errInvalidToken')
            ? 'Failed to join call: Invalid Agora token. Please try again.'
            : e.toString().contains('Microphone permission')
                ? 'Microphone permission required to join the call.'
                : 'Failed to join call: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    print('Disposing CallScreen, callId: $_callId');
    if (_callId != null) {
      _callService.leaveCall(_callId!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Voice Call from $_callerName')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              )
            else
              Text(_isJoined ? 'Connected to call' : 'Connecting...'),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    print('End Call button pressed');
                    if (_callId != null) {
                      await _callService.leaveCall(_callId!);
                    }
                    Navigator.pop(context);
                  },
                  child: const Text('End Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}