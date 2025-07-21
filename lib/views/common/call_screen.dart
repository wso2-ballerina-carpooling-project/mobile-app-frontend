import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

class CallingScreen extends StatefulWidget {
  final String token;
  final String channelName;
  final int uid;

  CallingScreen({required this.token, required this.channelName, required this.uid});

  @override
  _CallingScreenState createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  late final RtcEngine _engine;
  bool _joined = false;

  // Keep track of remote users who joined
  final Set<int> _remoteUsers = {};

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: '32f8dd6fbfad4a18986c278345678b41',channelProfile: ChannelProfileType.channelProfileCommunication));

   _engine.registerEventHandler(
  RtcEngineEventHandler(
    onJoinChannelSuccess: (connection, elapsed) {
      setState(() {
        _joined = true;
      });
    },
    onUserJoined: (connection, remoteUid, elapsed) {
      setState(() {
        _remoteUsers.add(remoteUid);
      });
    },
    onUserOffline: (connection, remoteUid, reason) {
      setState(() {
        _remoteUsers.remove(remoteUid);
      });
    },
    onError: (errorCode, message) {
      print('Agora error: $errorCode, message: $message');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Agora error: $errorCode')),
      );
    },
  ),
);


    await _engine.enableAudio();
    await _engine.joinChannel(
      token: widget.token,
      channelId: widget.channelName,
      uid: widget.uid,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_joined) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('In Call')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Connected to channel ${widget.channelName}'),
            const SizedBox(height: 20),
            Text(
              'Remote users joined:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _remoteUsers.isEmpty
                  ? const Text('No remote users connected yet')
                  : ListView.builder(
                      itemCount: _remoteUsers.length,
                      itemBuilder: (context, index) {
                        final uid = _remoteUsers.elementAt(index);
                        return ListTile(
                          leading: Icon(Icons.person),
                          title: Text('User ID: $uid'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
