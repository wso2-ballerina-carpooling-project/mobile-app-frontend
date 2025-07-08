import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0'; // Replace with your Ballerina backend URL
  //static const String baseUrl = 'http://192.168.90.103:9090/api'; // Replace with your Ballerina backend URL

  static Future<http.Response> registerUser(Map<String, dynamic> userData) async {
    final url = Uri.parse('$baseUrl/register');
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(userData);

    return await http.post(url, headers: headers, body: body);
  }
  static Future<http.Response> loginUser(Map<String, dynamic> loginData) async {
    final url = Uri.parse('$baseUrl/login');
    final headers = {
      'Content-Type': 'application/json'
    };
    final body = jsonEncode(loginData);

    return await http.post(url, headers: headers, body: body);
  }
}