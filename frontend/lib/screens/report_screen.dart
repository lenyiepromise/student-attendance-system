// frontend/lib/screens/report_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/api_service.dart';
import 'package:frontend/screens/daily_breakdown_screen.dart'; // <-- CORRECT: Imports the new screen

class ReportScreen extends StatefulWidget {
  final String courseCode;
  final String courseTitle;
  const ReportScreen({super.key, required this.courseCode, required this.courseTitle});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  late Future<Map<String, dynamic>> _reportFuture;
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    // CORRECT: Calls the renamed getSummaryReport function
    _reportFuture = _apiService.getSummaryReport(widget.courseCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Summary for ${widget.courseCode}"),
        // Adds the new button to the AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            tooltip: "View Daily Breakdown",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyBreakdownScreen(
                    courseCode: widget.courseCode,
                    courseTitle: widget.courseTitle,
                  ),
                ),
              );
            },
          )
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error fetching report: ${snapshot.error}"));
          } else if (!snapshot.hasData || (snapshot.data!['report'] as List).isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "No attendance has been taken for ${widget.courseTitle} yet.",
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            );
          }

          final reportData = snapshot.data!;
          final int totalDays = reportData['total_lecture_days'];
          final List<dynamic> studentReports = reportData['report'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.courseTitle,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  Card(
                    elevation: 2,
                    child: ListTile(
                      title: const Text("Total Unique Lecture Days"),
                      trailing: Text(
                        totalDays.toString(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: DataTable(
                      columnSpacing: 20,
                      headingRowColor: WidgetStateProperty.all(Colors.grey.shade200),
                      columns: const [
                        DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Matric No', style: TextStyle(fontWeight: FontWeight.bold))),
                        DataColumn(label: Text('Attended', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                        DataColumn(label: Text('%', style: TextStyle(fontWeight: FontWeight.bold)), numeric: true),
                      ],
                      rows: studentReports.map((studentData) {
                        final percentage = studentData['percentage'];
                        return DataRow(cells: [
                          DataCell(Text(studentData['full_name'])),
                          DataCell(Text(studentData['matric_no'])),
                          DataCell(Text(studentData['attended_days'].toString())),
                          DataCell(
                            Text(
                              '$percentage%',
                              style: TextStyle(
                                color: percentage >= 75 ? Colors.green.shade800 : Colors.red.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ]);
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}