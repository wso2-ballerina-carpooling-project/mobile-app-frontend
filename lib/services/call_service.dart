import 'package:http/http.dart' as http;
import 'dart:convert';

class CallService {
  static Future<String> getAgoraToken(String channelName, String userId) async {
  final response = await http.post(
    Uri.parse('http://192.168.42.103:3000/generateToken'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'channelName': channelName, 'uid': userId}),
  );
  if (response.statusCode == 200) {
    final Map<String, dynamic> json = jsonDecode(response.body);
    return json['token'] as String;
  }
  throw Exception('Failed to fetch Agora token');
}


  static Future<void> sendCallNotification({
    required String driverId,
    required String callId,
    required String channelName,
    required String callerName,
  }) async {
     final response = await http.post(
      Uri.parse('https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0/call'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'channelName': channelName, 'driverId': driverId,"callId":callId,"callerName":callerName}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to send call notification');
    }


  //   final response = await http.post(
  //     Uri.parse('https://fcm.googleapis.com/fcm/send'),
  //     headers: {
  //       'Content-Type': 'application/json',
  //       'Authorization': 'key=AIzaSyCAbKpJ6Hfyy6iySBLPxZHUumK1ojYP0Pw',
  //     },
  //     body: jsonEncode({
  //       'to': "fulCvDO4TZSW07rlZyBHfU:APA91bG2ZXKFE2cH6yoxAf8yI7iKg1_whWQBppPNczDzQDUCp7BioxUZDkachUUdxojyJ3vNRNAQSGbalj65sYTJilDS8hbOHOaMvQEDBPsbgVXZQhnbK1k",
  //       'data': {
  //         'callId': callId,
  //         'channelName': channelName,
  //         'callerName': callerName,
  //       },
  //       'notification': {
  //         'title': 'Incoming Call',
  //         'body': 'Call from $callerName',
  //       },
  //     }),
  //   );
  //   if (response.statusCode != 200) {
  //     throw Exception('Failed to send call notification');
  //   }
  }

  // Existing methods like loginUser, sendFCM...
}