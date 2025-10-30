import 'package:flutter/material.dart';
import 'package:growth_tracker/models/reminder.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  // API service methods will be implemented here

  final String baseUrl = "http://10.0.2.2:5058/api";

  Future<List<Reminder>> fetchReminders() async {
    final response = await http.get(Uri.parse('$baseUrl/reminders/upcoming'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      return body.map((item) => Reminder.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  Future<void> addReminder(Reminder reminder) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reminders'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'title': reminder.title,
        'description': reminder.description,
        'reminderDate': reminder.reminderDate.toIso8601String(),
        'isCompleted': reminder.isCompleted,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add reminder');
    }
  }

  Future<void> sendTokenToServer(String token, String platform) async {
    final url = Uri.parse('$baseUrl/device_token');
    final body = jsonEncode({
      'deviceId': '',
      'platform': platform,
      'token': token,
    });

    try {
      final response = await http.post(url,
          headers: {"Content-Type": "application/json"}, body: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Token sent successfully to server.');
      } else {
        print(
            'Failed to send token to server. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending token to server: $e');
    }
  }
}
