// lib/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // IMPORTANT: For Windows desktop app, 127.0.0.1 is correct.
  // For an Android Emulator, use http://10.0.2.2:8000/api
  // For a physical phone, find your computer's IP address (e.g., http://192.168.1.10:8000/api)
  final String _baseUrl = "http://127.0.0.1:8000/api";

  // --- Login Method ---
  Future<String?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/token/"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("access_token", data["access"]);
        return data["access"];
      }
    } catch (e) {
      // This will print the detailed error to your Flutter console
      print("Login Error: $e");
    }
    return null;
  }

  // --- Get Courses Method (NEW) ---
  Future<List<Map<String, String>>> getCourses() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access_token");

  if (token == null) return [];

  try {
    final response = await http.get(
      Uri.parse("$_baseUrl/courses/"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      // Map the 'lecturer_name' field
      return data.map((course) => {
        "course_code": course["course_code"].toString(),
        "course_title": course["course_title"].toString(),
        "lecturer_name": course["lecturer_name"].toString(),
      }).toList();
    }
  } catch (e) {
    print("Get Courses Error: $e");
  }
  return [];
}

  // --- Record Attendance Method ---
  Future<Map<String, dynamic>> recordAttendance(String qrData, String courseCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    if (token == null) {
      return {"success": false, "message": "Authentication token not found."};
    }

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/record-attendance/"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"qr_data": qrData, "course_code": courseCode}),
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {"success": true, "message": data["success"]};
      } else {
        return {"success": false, "message": data["error"] ?? "An unknown error occurred."};
      }
    } catch (e) {
      // This will print the detailed error to your Flutter console
      print("Record Attendance Error: $e");
      return {"success": false, "message": "Could not connect to the server."};
    }
  }

   // --- Logout Method ---
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    // Remove the saved token from the device
    await prefs.remove("access_token");
  }

  // --- Get Attendance Report Method ---

  Future<Map<String, dynamic>> getSummaryReport(String courseCode) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString("access_token");

  if (token == null) throw Exception('Authentication Token not found.');

  try {
    final uri = Uri.parse("$_baseUrl/report/summary/").replace(queryParameters: {'course_code': courseCode});
    
    final response = await http.get(uri, headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load summary report.');
    }
  } catch (e) {
    print("Get Summary Report Error: $e");
    throw Exception('Could not connect to get summary report.');
  }
}
  // --- Get Daily Report Method ---
  Future<Map<String, dynamic>> getDailyReport(String courseCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("access_token");

    if (token == null) throw Exception('Authentication Token not found.');

    try {
      final uri = Uri.parse("$_baseUrl/report/daily/").replace(queryParameters: {'course_code': courseCode});

      final response = await http.get(uri, headers: {"Authorization": "Bearer $token"});

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to load daily report.');
      }
    } catch (e) {
      print("Get Daily Report Error: $e");
      throw Exception('Could not connect to get daily report.');
    }
 }
}