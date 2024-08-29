import 'dart:convert';
import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:m_worker/utils/prefs.dart';

import 'api_errors/refresh_token_error_dialog.dart';

class Api {
  static const String baseUrl =
      'http://192.168.0.110:5001'; // https://moscare-api-master.vercel.app //http://192.168.0.110:5001
  static bool _isRefreshing = false; // Flag to track token refresh attempts

  static Future<String?> _refreshToken() async {
    if (_isRefreshing) {
      return null; // Prevent multiple simultaneous refresh attempts
    }
    _isRefreshing = true;

    try {
      final email = await Prefs.getEmail();
      final password = await Prefs.getPassword();
      log('Refreshing token for $email');
      if (email != null && password != null) {
        var credentials;
        try {
          credentials = await FirebaseAuth.instance
              .signInWithEmailAndPassword(email: email, password: password);
        } catch (e) {
          log('Error refreshing token: $e');
          _isRefreshing = true; // Reset the flag even if there's an error
          showTokenRefreshErrorDialog(); // Show the error dialog
          return null;
        }
        String? bearer = await credentials.user!.getIdToken();
        await Prefs.setToken(bearer!);
        _isRefreshing = false;
        return bearer;
      } else {
        _isRefreshing = true;
        showTokenRefreshErrorDialog();
        return null;
      }
    } catch (e) {
      log('Error refreshing token: $e');
      _isRefreshing = true; // Reset the flag even if there's an error
      showTokenRefreshErrorDialog(); // Show the error dialog
    }
    _isRefreshing = false; // Ensure the flag is reset before exiting
    return null;
  }

  static Future<dynamic> _makeRequest(String method, String endpoint,
      {Map<String, dynamic>? data}) async {
    final token = await Prefs.getToken();
    final bearerToken = 'Bearer $token';
    final uri = Uri.parse('$baseUrl/api/$endpoint');
    final headers = {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': bearerToken,
    };

    http.Response response;
    try {
      if (method == 'GET') {
        response = await http.get(uri, headers: headers);
      } else if (method == 'POST') {
        response =
            await http.post(uri, headers: headers, body: jsonEncode(data));
      } else if (method == 'PUT') {
        response =
            await http.put(uri, headers: headers, body: jsonEncode(data));
      } else if (method == 'DELETE') {
        response =
            await http.delete(uri, headers: headers, body: jsonEncode(data));
      } else {
        throw UnsupportedError('Unsupported HTTP method: $method');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else if (response.statusCode == 403 && !_isRefreshing) {
        // Attempt to refresh token if not already refreshing
        await _refreshToken();
        // Retry the request after token refresh
        return await _makeRequest(method, endpoint, data: data);
      } else {
        log('Error ($method): ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      log('Error ($method): $e');
    }
    return null;
  }

  static Future get(String endpoint, [Map<String, dynamic>? data]) async {
    return await _makeRequest('GET', endpoint, data: data);
  }

  static Future post(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest('POST', endpoint, data: data);
  }

  static Future put(String endpoint, Map<String, dynamic> data) async {
    return await _makeRequest('PUT', endpoint, data: data);
  }

  static Future delete(String endpoint, [Map<String, dynamic>? data]) async {
    return await _makeRequest('DELETE', endpoint, data: data);
  }
}
