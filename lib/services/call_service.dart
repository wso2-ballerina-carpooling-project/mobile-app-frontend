import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallService {
  RtcEngine? _engine;
  final String appId = 'your-agora-app-id'; // Replace with your Agora App ID
  final String backendUrl = 'http://your-ballerina-backend:9090/api';

  Future<void> initAgora(String channelName) async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    await _engine!.enableAudio();
    await _engine!.joinChannel(
      token: '', // No token for testing
      channelId: channelName,
      uid: 0,
      options: ChannelMediaOptions(),
    );
  }

  Future<Map<String, String>> initiateCall(String callerId, String receiverId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/initiateCall'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'callerId': callerId,
        'receiverId': receiverId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, String>;
    } else {
      throw Exception('Failed to initiate call: ${response.body}');
    }
  }

  Future<Map<String, String>> getCallDetails(String callId) async {
    final response = await http.get(
      Uri.parse('$backendUrl/callDetails?callId=$callId'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, String>;
    } else {
      throw Exception('Failed to fetch call details: ${response.body}');
    }
  }

  Future<void> updateFcmToken(String userId, String fcmToken) async {
    final response = await http.post(
      Uri.parse('$backendUrl/updateFcmToken'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'fcmToken': fcmToken,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update FCM token: ${response.body}');
    }
  }

  Future<void> leaveCall(String callId) async {
    await _engine?.leaveChannel();
    await _engine?.release();
    await http.post(
      Uri.parse('$backendUrl/endCall'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'callId': callId}),
    );
  }
}