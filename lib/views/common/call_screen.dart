import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class CallScreen extends StatelessWidget {
  final String fromUser = "userA";
  final String toUser = "userB";

  Future<void> initiateMaskedCall() async {
    final uri = Uri.parse("https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0/call");
    
    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "fromUser": fromUser,
        "toUser": toUser,
      }),
    );

    if (response.statusCode == 200) {
      // You don't need to process XML here
      // Instead, launch the Twilio phone number directly
      const twilioNumber = "tel:+13185953040"; // your Twilio number
      if (await canLaunchUrl(Uri.parse(twilioNumber))) {
        await launchUrl(Uri.parse(twilioNumber));
      } else {
        print("Could not launch call");
      }
    } else {
      print("Failed to initiate masked call: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Masked Call")),
      body: Center(
        child: ElevatedButton(
          onPressed: initiateMaskedCall,
          child: Text("Call User B (Masked)"),
        ),
      ),
    );
  }
}