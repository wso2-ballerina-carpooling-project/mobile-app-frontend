import 'dart:convert';
import 'package:http/http.dart' as http;

String baseUrl = 'https://6a087cec-06ac-4af3-89fa-e6e37f8ac222-dev.e1-us-east-azure.choreoapis.dev/service-carpool/carpool-service/v1.0';

class MapServices {
  static Future<List<Map<String, dynamic>>> searchSriLankaPlaces(
    String query,
  ) async {
    if (query.length < 3) return [];

    try {
      final response = await http.post(
        Uri.parse(baseUrl + '/searchLocation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text': query}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['places'] is List) {
          return (data['places'] as List).map<Map<String, dynamic>>((place) {
            return {
              'description': place['displayName']['text'],
              'place_id': place['id'],
            };
          }).toList();
        }
      } else {
        print('Backend returned error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error contacting backend: $e');
    }

    return [];
  }
}
