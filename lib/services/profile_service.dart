import 'dart:convert';
import 'package:http/http.dart' as http;

class ProfileService {
  static const String baseUrl = 'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0'; // Replace with your Ballerina backend URL
  //static const String baseUrl = 'http://192.168.90.103:9090/api'; // Replace with your Ballerina backend URL

  static Future<http.Response> editName(Map<String, dynamic> nameData, String token) async {
    final url = Uri.parse('$baseUrl/editName');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Include JWT token for authentication
    };
    final body = jsonEncode(nameData);

    return await http.post(url, headers: headers, body: body);
  }

  static Future<http.Response> editPhone(Map<String, dynamic> phoneData, String token) async {
    final url = Uri.parse('$baseUrl/editPhone');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // Include JWT token for authentication
    };
    final body = jsonEncode(phoneData);

    return await http.post(url, headers: headers, body: body);
  }

  static Future<http.Response> editVehicle(Map<String, dynamic> vehicleData, String token) async {
    final url = Uri.parse('$baseUrl/updateVehicle');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', 
    };
    final body = jsonEncode(vehicleData);

    return await http.post(url, headers: headers, body: body);
  }
}