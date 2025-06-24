import 'package:http/http.dart' as http;
import 'dart:convert';

class RideService {
  static const String baseUrl =
      'http://172.20.10.3:9090/api'; // Replace with your backend URL

  static Future<http.Response> postRide(
    Map<String, dynamic> rideData,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/postRide');
    print(url);
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json','Authorization': 'Bearer $token',},
      body: jsonEncode(rideData),
    );
  }
  static Future<http.Response> rideSearch(
    Map<String, dynamic> rideData,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/search');
    print(url);
    return await http.post(
      url,
      headers: {'Content-Type': 'application/json','Authorization': 'Bearer $token',},
      body: jsonEncode(rideData),
    );
  }
}
