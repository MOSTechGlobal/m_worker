import 'dart:convert';
import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Api {
  static const String baseUrl = 'http://192.168.0.110:5000';

  static Future<String?> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('userEmail');
      final password = prefs.getString('userPassword');
      final credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email!, password: password!);
      String? bearer = await credentials.user!.getIdToken();
      await prefs.setString('bearer', bearer!);
    } catch (e) {
      log('Error refreshing token: $e');
    }
    return null; // Return null to indicate refresh failure
  }

  // GET request method
  static Future get(String endpoint, [Map<String, String>? queryParams]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bearerToken = 'Bearer ${prefs.getString("bearer")}';

      final uri = Uri.parse('$baseUrl/api/$endpoint').replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json; charset=UTF-8', 'Authorization': bearerToken},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        // Attempt to refresh the Firebase token
        await _refreshToken();
        // Retry the request
        return await get(endpoint, queryParams);
      } else {
        log('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error: $e');
    }
    return null;
  }

  // POST request method
  static Future post(String endpoint, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bearerToken = 'Bearer ${prefs.getString("bearer")}';

      final uri = Uri.parse('$baseUrl/api/$endpoint');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': bearerToken,
        },
        body: jsonEncode(data),  // Encode the data as JSON
      );

      if (response.statusCode == 200 || response.statusCode == 201) { // Successful POST responses might have 201 Created
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        // Attempt to refresh token
        await _refreshToken();
        // Retry the POST request
        return await post(endpoint, data);
      } else {
        log('Error (POST): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error (POST): $e');
    }
    return null;
  }

  // PUT request method
  static Future put(String endpoint, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bearerToken = 'Bearer ${prefs.getString("bearer")}';

      final uri = Uri.parse('$baseUrl/api/$endpoint');

      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': bearerToken,
        },
        body: jsonEncode(data),  // Encode the data as JSON
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        // Attempt to refresh token
        await _refreshToken();
        // Retry the PUT request
        return await put(endpoint, data);
      } else {
        log('Error (PUT): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error (PUT): $e');
    }
    return null;
  }

  // DELETE request method
  static Future delete(String endpoint, [Map<String, dynamic>? data]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bearerToken = 'Bearer ${prefs.getString("bearer")}';

      final uri = Uri.parse('$baseUrl/api/$endpoint');

      final response = await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': bearerToken,
        },
        // Encode the data as JSON if it exists
        body: data != null ? jsonEncode(data) : null,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 403) {
        // Attempt to refresh token
        await _refreshToken();
        // Retry the DELETE request
        return await delete(endpoint, data);
      } else {
        log('Error (DELETE): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error (DELETE): $e');
    }
    return null;
  }

// Add other HTTP methods (post, put, delete) as needed...

}
