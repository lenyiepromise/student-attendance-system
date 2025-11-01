// lib/screens/daily_breakdown_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/api_service.dart';

class DailyBreakdownScreen extends StatefulWidget {
  final String courseCode;
  final String courseTitle;
  const DailyBreakdownScreen({super.key, required this.courseCode, required this.courseTitle});

  @override
  State<DailyBreakdownScreen> createState() => _DailyBreakdownScreenState();
}

class _DailyBreakdownScreenState extends State<DailyBreakdownScreen> {
  late Future<Map<String, dynamic>> _dailyReportFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _dailyReportFuture = _apiService.getDailyReport(widget.courseCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Daily Breakdown for ${widget.courseCode}")),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dailyReportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text("Could not load daily report."));
          }

          final List<dynamic> breakdown = snapshot.data!['daily_breakdown'];

          if (breakdown.isEmpty) {
            return const Center(child: Text("No attendance records found."));
          }

          return ListView.builder(
            itemCount: breakdown.length,
            itemBuilder: (context, index) {
              final dayData = breakdown[index];
              final String date = dayData['date'];
              final List<dynamic> attendees = dayData['attendees'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${attendees.length} student(s) present"),
                  children: attendees.map<Widget>((attendee) {
                    return ListTile(
                      title: Text(attendee['full_name']),
                      subtitle: Text(attendee['matric_no']),
                      dense: true,
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}