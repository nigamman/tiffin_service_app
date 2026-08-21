import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';


class ApiClient {
  final http.Client _client = http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  Future<http.Response> get(String endpoint) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await _client.get(url, headers: headers);
      _logResponse('GET', url.toString(), response);
      return response;
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await _client.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse('POST', url.toString(), response);
      return response;
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final url = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _getHeaders();
    
    try {
      final response = await _client.put(
        url,
        headers: headers,
        body: jsonEncode(body),
      );
      _logResponse('PUT', url.toString(), response);
      return response;
    } catch (e) {
      throw Exception('Network connection failed: $e');
    }
  }

  void _logResponse(String method, String url, http.Response response) {
    if (kDebugMode) {
      print('--- API REQUEST ---');
      print('$method: $url');
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
      print('-------------------');
    }
  }
}

// Global debug flag wrapper for Flutter compilation
const bool kDebugMode = !kReleaseMode;
