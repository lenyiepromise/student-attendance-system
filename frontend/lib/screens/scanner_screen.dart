// lib/screens/scanner_screen.dart

import 'package:flutter/material.dart';
import 'package:frontend/api_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  final String courseCode;
  const ScannerScreen({super.key, required this.courseCode});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && mounted) {
      final String qrData = barcodes.first.rawValue ?? "No data found";
      
      final result = await _apiService.recordAttendance(qrData, widget.courseCode);

      // Get the detailed message and success status from the backend's response
      final String message = result["message"]; 
      final bool success = result["success"];

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message), // This will now show "Success! Lenyie Promise marked present." etc.
          backgroundColor: success ? Colors.green.shade700 : Colors.red.shade700,
          duration: const Duration(seconds: 4), // Give more time to read the message
        ),
      );
      
      await Future.delayed(const Duration(seconds: 3));
    }
    
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Scanning for ${widget.courseCode}")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text("Processing...", style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}