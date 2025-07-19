import 'package:flutter/material.dart';
import 'package:mobile_frontend/services/call_service.dart';

class CallScreen extends StatefulWidget {
  @override
  _CallScreenState createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final CallService _callService = CallService();
  bool _isJoined = false;
  String? _callId;
  String _callerName = 'Unknown';

  @override
  void initState() {
    super.initState();
    _joinCall();
  }

  Future<void> _joinCall() async {
    final args = ModalRoute.of(context)!.settings.arguments as Map;
    _callId = args['callId'];
    String? channelName = args['channelName'];
    String? callerName = args['callerName'];

    try {
      final callDetails = await _callService.getCallDetails(_callId!);
      setState(() {
        _callerName = callDetails['callerName'] ?? callerName ?? 'Unknown';
        channelName ??= callDetails['channelName'];
      });

      await _callService.initAgora(channelName!);
      setState(() => _isJoined = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error joining call: $e')),
      );
    }
  }

  @override
  void dispose() {
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
            Text(_isJoined ? 'Connected to call' : 'Connecting...'),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _callService.leaveCall(_callId!);
                    Navigator.pop(context);
                  },
                  child: Text('End Call'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}