// frontend/lib/screens/course_list_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/api_service.dart';
import 'package:frontend/screens/login_screen.dart';
import 'package:frontend/screens/report_screen.dart'; // Import the report screen
import 'package:frontend/screens/scanner_screen.dart';

class CourseListScreen extends StatefulWidget {
  const CourseListScreen({super.key});
  @override
  State<CourseListScreen> createState() => _CourseListScreenState();
}

class _CourseListScreenState extends State<CourseListScreen> {
  late Future<List<Map<String, String>>> _coursesFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _coursesFuture = _apiService.getCourses();
  }

  void _handleLogout() async {
    await _apiService.logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  void _showConfirmationDialog(BuildContext context, Map<String, String> course) {
    final assignedLecturer = course["lecturer_name"] ?? "Not Assigned";
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(course["course_title"]!),
          content: Text(
              "You are about to start an attendance session for ${course["course_code"]}.\n\n"
              "Official Lecturer: $assignedLecturer\n\n"
              "Do you confirm you are taking this class?"),
          actions: <Widget>[
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            FilledButton(
              child: const Text("Confirm and Scan"),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ScannerScreen(courseCode: course["course_code"]!),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select a Course"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, String>>>(
        future: _coursesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No courses available in the system."));
          }

          final courses = snapshot.data!;
          return ListView.builder(
            itemCount: courses.length,
            itemBuilder: (context, index) {
              final course = courses[index];
              
              return Card(
                elevation: 2,
                margin:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(course["course_title"]!,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text("Code: ${course["course_code"]!}",
                          style: Theme.of(context).textTheme.bodySmall),
                      Text("Lecturer: ${course["lecturer_name"]!}",
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.bar_chart_outlined, size: 18),
                            label: const Text("View Report"),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReportScreen(
                                    courseCode: course["course_code"]!,
                                    courseTitle: course["course_title"]!,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            icon: const Icon(Icons.qr_code_scanner, size: 18),
                            label: const Text("Start Scan"),
                            onPressed: () {
                              _showConfirmationDialog(context, course);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}