
import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/timetable_service.dart';
import '../../models/timetable_model.dart';
import '../../core/theme/app_theme.dart';

class TimetableImportScreen extends StatefulWidget {
  const TimetableImportScreen({Key? key}) : super(key: key);

  @override
  State<TimetableImportScreen> createState() => _TimetableImportScreenState();
}

class _TimetableImportScreenState extends State<TimetableImportScreen> {
  final TimetableService _service = TimetableService();
  File? _selectedFile;
  bool _isScanning = false;
  Timetable? _extractedTimetable;
  String? _statusMessage;
  String _debugLogs = ""; // Store debug logs
  bool _showDebug = false;

  @override
  void initState() {
    super.initState();
    // Show instructions after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInstructions();
    });
  }

  void _showInstructions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Before you scan..."),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text("To get the best results:"),
            SizedBox(height: 10),
            Text("• Upload a clear IMAGE or PDF of your timetable."),
            Text("• Ensure good lighting if taking a photo."),
            Text("• The grid lines should be visible."),
            Text("• Lab sessions (Yellow boxes) will be auto-detected."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(bool isPdf) async {
    try {
      final file = await _service.pickImageOrPdf(isPdf);
      if (file != null) {
        setState(() {
          _selectedFile = file;
          _extractedTimetable = null;
        });
        _processFile(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
    }
  }

  Future<void> _processFile(File file) async {
    setState(() {
      _isScanning = true;
      _statusMessage = "Analyzing text...";
    });

    try {
      final result = await _service.extractTimetable(file);
      
      setState(() {
        _extractedTimetable = result.timetable;
        _debugLogs = result.debugLog;
        _isScanning = false;
        _statusMessage = null;
        
        // Auto-show debug if empty
        if (_extractedTimetable!.weekSchedule.values.every((l) => l.isEmpty)) {
            _showDebug = true;
        }
      });
    } catch (e) {
      setState(() {
        _isScanning = false;
        _statusMessage = "Failed to scan: $e";
        _debugLogs = "Error: $e";
        _showDebug = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Import Timetable")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_selectedFile != null) ...[
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: FileImage(_selectedFile!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ] else
               Container(
                height: 200,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, style: BorderStyle.none),
                  color: Colors.grey[200],                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("No image selected"),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            if (_isScanning)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_statusMessage ?? "Processing..."),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(false),
                    icon: const Icon(Icons.photo),
                    label: const Text("Pick Image"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickFile(true),
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Pick PDF"),
                  ),
                ],
              ),

             const SizedBox(height: 24),
             if (_showDebug) 
               Container(
                 padding: const EdgeInsets.all(8),
                 color: Colors.black12,
                 width: double.infinity,
                 child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        const Text("Debug Info:", style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(_debugLogs, style: const TextStyle(fontFamily: 'monospace', fontSize: 10)),
                    ]
                 )
               ),
             
             if (_extractedTimetable != null) _buildResultPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Detected Schedule:", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._extractedTimetable!.weekSchedule.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox.shrink();
          return Card(
            child: ExpansionTile(
              title: Text(entry.key),
              children: entry.value.map((slot) => ListTile(
                leading: Text("${slot.startTime}\n${slot.endTime}", textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                title: Text(slot.subject, style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: slot.isLab ? Colors.orange[800] : Colors.black
                )),
                subtitle: Text(slot.isLab ? "LAB" : "Theory"),
                trailing: slot.isLab ? const Icon(Icons.science, color: Colors.orange) : null,
              )).toList(),
            ),
          );
        }).toList(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (_extractedTimetable != null) {
                await _service.saveTimetable(_extractedTimetable!);
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Timetable Saved!")),
                );
                // ignore: use_build_context_synchronously
                Navigator.pop(context, true); // Return true to indicate refresh needed
              }
            }, 
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Save Timetable"),
          ),
        )
      ],
    );
  }
}
