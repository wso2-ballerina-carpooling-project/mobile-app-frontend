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

  static Future<List<Ride>> fetchDriverCompleted(
    FlutterSecureStorage storage,
  ) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) return [];

      final response = await http.post(
        Uri.parse('$baseUrl/driverRideInfor'),
        headers: {'Authorization': 'Bearer $token'},
      );

      print('Response status code: ${response.statusCode}');

      Map<String, dynamic> payload = Jwt.parseJwt(token);
      int seatingCapacity = int.parse(
        payload['driverDetails']['seatingCapacity'].toString(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rides'];

        rideList.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA); // Latest date first
        });

        return rideList
            .map((rideJson) => Ride.fromJson(rideJson, seatingCapacity))
            .where((ride) => ride.status == 'completed')
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

  static Future<List<Ride>> fetchDriverOngoing(
    FlutterSecureStorage storage,
  ) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/ongoingDriverRide'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rides'];

        rideList.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA);
        });

        return rideList
            .map(
              (rideJson) => Ride.fromJson(rideJson, 0),
            ) // Adjust seatingCapacity if needed
            .where((ride) => ride.status == 'active')
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching ongoing rides: $e');
      return [];
    }
  }

  static Future<List<Ride>> fetchDriverCanceled(
    FlutterSecureStorage storage,
  ) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/cancelDriverRide'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rides'];

        rideList.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA);
        });

        return rideList
            .map(
              (rideJson) => Ride.fromJson(rideJson, 0),
            ) // Adjust seatingCapacity if needed
            .where((ride) => ride.status == 'cancel')
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching canceled rides: $e');
      return [];
    }
  }

  static Future<List<Ride>> fetchPassengerOngoing(
    FlutterSecureStorage storage,
  ) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('http://192.168.8.109:9090/api/passengerOngoingRide'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print(data);
        final List<dynamic> rideList = data['rideDoc'];

        rideList.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA);
        });

        return rideList.map((rideJson) => Ride.fromJson(rideJson, 0)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching passenger ongoing rides: $e');
      return [];
    }
  }

  static Future<List<Ride>> fetchPassengerCompleted(
    FlutterSecureStorage storage,
  ) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('http://192.168.8.109:9090/api/passengerCompleteRide'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rideDoc'];

        rideList.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA);
        });

        return rideList.map((rideJson) => Ride.fromJson(rideJson, 0)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching passenger completed rides: $e');
      return [];
    }
  }

  static Future<List<Ride>> fetchPassengerCanceled(
    FlutterSecureStorage storage,
  ) async {
    try {
      String? token = await storage.read(key: 'jwt_token');
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$baseUrl/canceledPassengerRide'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> rideList = data['rides'];

        rideList.sort((a, b) {
          DateTime dateA = _parseDate(a['date']);
          DateTime dateB = _parseDate(b['date']);
          return dateB.compareTo(dateA);
        });

        return rideList
            .map((rideJson) => Ride.fromJson(rideJson, 0))
            .where((ride) => ride.status == 'canceled')
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching passenger canceled rides: $e');
      return [];
    }
  }

  static DateTime _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3)
        throw FormatException('Invalid date format: $dateStr');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      print('Error parsing date $dateStr: $e');
      return DateTime(1970, 1, 1);
    }
  }
}
