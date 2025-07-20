import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CallService {
  RtcEngine? _engine;
  final String appId = '32f8dd6fbfad4a18986c278345678b41'; // Replace with your Agora App ID
  final String backendUrl = 'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';

  Future<void> initAgora(String channelName, String token) async {
    try {
      print('Initializing Agora with channel: $channelName');
      _engine = createAgoraRtcEngine();
      await _engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      // Set up Agora event handlers for debugging
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            print('Joined channel ${connection.channelId} with uid ${connection.localUid}');
          },
          onError: (ErrorCodeType err, String msg) {
            print('Agora error: $err, $msg');
          },
          onConnectionStateChanged: (RtcConnection connection, ConnectionStateType state, ConnectionChangedReasonType reason) {
            print('Connection state changed: $state, reason: $reason');
          },
        ),
      );

      await _engine!.enableAudio();
      await _engine!.joinChannel(
        token: token, // No token for testing
        channelId: channelName,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          channelProfile: ChannelProfileType.channelProfileCommunication,
        ),
      );
      print('Join channel request sent for $channelName');
    } catch (e) {
      print('Failed to initialize Agora: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> initiateCall(String callerId, String receiverId) async {
    final response = await http.post(
      Uri.parse('$backendUrl/initiateCall'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'callerId': callerId,
        'receiverId': receiverId,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
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