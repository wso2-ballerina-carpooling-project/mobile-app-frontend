import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mobile_frontend/models/RideData.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decode/jwt_decode.dart';

class RideService {
  static final FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String baseUrl =
      'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-prod.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0'; // Replace with your backend URL

  static Future<http.Response> postRide(
    Map<String, dynamic> rideData,
    String token,
  ) async {
    final url = Uri.parse('$baseUrl/postRide');
    print(url);
    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
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
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(rideData),
    );
  }

  static Future<List<Ride>> fetchDriverRides() async {
    try {
      String? token = await _storage.read(key: 'jwt_token');
      if (token == null) return [];

      Map<String, dynamic> payload = Jwt.parseJwt(token);
      int seatingCapacity = int.parse(
        payload['driverDetails']['seatingCapacity'].toString(),
      );

      final response = await http.post(
        Uri.parse('$baseUrl/getRide'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print(response.statusCode);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rides'];

        return rideList
            .map((rideJson) => Ride.fromJson(rideJson, seatingCapacity))
            .where((ride) => ride.status == 'active')
            .toList();
      } else {
        print('Failed to fetch rides: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching rides: $e');
      return [];
    }
  }
}
