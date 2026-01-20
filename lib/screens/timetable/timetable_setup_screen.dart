import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/timetable_model.dart';
import '../../services/timetable_service.dart';

class TimetableSetupScreen extends StatefulWidget {
  const TimetableSetupScreen({Key? key}) : super(key: key);

  @override
  State<TimetableSetupScreen> createState() => _TimetableSetupScreenState();
}

class _TimetableSetupScreenState extends State<TimetableSetupScreen> with SingleTickerProviderStateMixin {
  final TimetableService _service = TimetableService();
  late TabController _tabController;
  
  List<Subject> _subjects = [];
  List<Faculty> _faculties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final s = await _service.loadSubjects();
    final f = await _service.loadFaculties();
    setState(() {
      _subjects = s;
      _faculties = f;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Timetable Data"),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Subjects"),
            Tab(text: "Faculty"),
            Tab(text: "Backup"),
          ],
        ),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectsTab(),
                _buildFacultyTab(),
                _buildBackupTab(),
              ],
            ),
    );
  }

  // --- Subjects Tab ---

  Widget _buildSubjectsTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddSubjectDialog(),
        child: const Icon(Icons.add),
      ),
      body: _subjects.isEmpty 
          ? const Center(child: Text("No subjects added yet"))
          : ListView.builder(
              itemCount: _subjects.length,
              itemBuilder: (context, index) {
                final subject = _subjects[index];
                return ListTile(
                  title: Text(subject.name),
                  subtitle: Text("Code: ${subject.code}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _service.removeSubject(subject);
                      _loadData();
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddSubjectDialog() async {
    final nameController = TextEditingController();
    final codeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Subject"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Subject Name")),
            const SizedBox(height: 10),
            TextField(controller: codeController, decoration: const InputDecoration(labelText: "Subject Code")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _service.addSubject(Subject(
                  name: nameController.text, 
                  code: codeController.text
                ));
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // --- Faculty Tab ---

  Widget _buildFacultyTab() {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddFacultyDialog(),
        child: const Icon(Icons.add),
      ),
      body: _faculties.isEmpty 
          ? const Center(child: Text("No faculty members added yet"))
          : ListView.builder(
              itemCount: _faculties.length,
              itemBuilder: (context, index) {
                final faculty = _faculties[index];
                return ListTile(
                  title: Text(faculty.name),
                  subtitle: Text("Short: ${faculty.shortName}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      await _service.removeFaculty(faculty);
                      _loadData();
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddFacultyDialog() async {
    final nameController = TextEditingController();
    final shortController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Faculty"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Faculty Name")),
            const SizedBox(height: 10),
            TextField(controller: shortController, decoration: const InputDecoration(labelText: "Short Name (e.g. ABC)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _service.addFaculty(Faculty(
                  name: nameController.text, 
                  shortName: shortController.text
                ));
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text("Add"),
          )
        ],
      ),
    );
  }

  // --- Backup Tab ---

  Widget _buildBackupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info banner explaining the feature
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      "Why Backup?",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.help_outline, color: Colors.blue.shade700),
                      onPressed: _showHelpDialog,
                      tooltip: "How to use",
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "• Share your timetable with classmates instantly\n"
                  "• Restore data if you reinstall the app\n"
                  "• One person can set up, everyone can import!",
                  style: TextStyle(
                    color: Colors.blue.shade900,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Export Section
          const Text("Export Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Share your timetable data with others or create a backup."),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _exportAsFile,
            icon: const Icon(Icons.share),
            label: const Text("Export as File"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white, 
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.copy),
            label: const Text("Copy Code to Clipboard"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
            ),
          ),
          
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 30),
          
          // Import Section
          const Text("Import Data", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text("Restore data from a file or paste code shared by others."),
          const SizedBox(height: 16),
          
          ElevatedButton.icon(
            onPressed: _importFromFile,
            icon: const Icon(Icons.upload_file),
            label: const Text("Import from File"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          
          ElevatedButton.icon(
            onPressed: _showPasteCodeDialog,
            icon: const Icon(Icons.paste),
            label: const Text("Paste Code"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),

          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          
          OutlinedButton.icon(
            onPressed: _clearData,
            icon: const Icon(Icons.delete_forever),
            label: const Text("Clear All Data"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text("How to Use Backup"),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("📤 TO SHARE YOUR TIMETABLE:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("1. Add your subjects, faculty & classes first\n"
                   "2. Come to Backup tab\n"
                   "3. Tap 'Copy Code to Clipboard'\n"
                   "4. Share the code with friends via WhatsApp/Telegram"),
              SizedBox(height: 16),
              Text("📥 TO GET SOMEONE'S TIMETABLE:", style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text("1. Ask a classmate to share their code\n"
                   "2. Come to Backup tab\n"
                   "3. Tap 'Paste Code'\n"
                   "4. Paste the code and tap Import\n"
                   "5. Done! Timetable is now on your phone"),
              SizedBox(height: 16),
              Text("💡 TIP:", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              SizedBox(height: 8),
              Text("One class representative can set up the timetable "
                   "and share the code with the entire class!",
                   style: TextStyle(fontStyle: FontStyle.italic)),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: const Text("Got it!"),
          ),
        ],
      ),
    );
  }

  // Export as file (existing functionality)
  Future<void> _exportAsFile() async {
    try {
      final jsonString = await _service.exportData();
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/timetable_backup.json');
      await file.writeAsString(jsonString);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'My Timetable Data Backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Export failed: $e")));
      }
    }
  }

  // Copy JSON to clipboard (new functionality)
  Future<void> _copyToClipboard() async {
    try {
      final jsonString = await _service.exportData();
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text("Timetable code copied to clipboard!"),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Copy failed: $e")));
      }
    }
  }

  // Import from file (existing functionality)
  Future<void> _importFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        String content;
        
        if (result.files.single.bytes != null) {
          content = utf8.decode(result.files.single.bytes!);
        } else if (result.files.single.path != null) {
          File file = File(result.files.single.path!);
          content = await file.readAsString();
        } else {
          throw Exception("Could not read file");
        }
        
        if (!content.trim().startsWith('{')) {
          throw Exception("Invalid file format. Please select a JSON backup file.");
        }
        
        bool success = await _service.importData(content);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(
             content: Text(success ? "Data imported successfully!" : "Failed to import data. Check file format."),
             backgroundColor: success ? Colors.green : Colors.red,
           ));
           if (success) _loadData();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Import failed: $e"),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // Paste code dialog (new functionality)
  Future<void> _showPasteCodeDialog() async {
    final codeController = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.paste, color: Colors.orange),
            SizedBox(width: 8),
            Text("Paste Timetable Code"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Paste the JSON code shared by someone else:",
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: codeController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: '{"timetable": {...}, "subjects": [...]}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData(Clipboard.kTextPlain);
                  if (data?.text != null) {
                    codeController.text = data!.text!;
                  }
                },
                icon: const Icon(Icons.content_paste, size: 16),
                label: const Text("Paste from Clipboard"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please paste some code first")),
                );
                return;
              }
              
              if (!code.startsWith('{')) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Invalid format. Code must be valid JSON."),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              try {
                final success = await _service.importData(code);
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(success ? "Timetable imported successfully!" : "Failed to import. Check code format."),
                  backgroundColor: success ? Colors.green : Colors.red,
                ));
                
                if (success) _loadData();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text("Import error: $e"),
                  backgroundColor: Colors.red,
                ));
              }
            },
            icon: const Icon(Icons.download),
            label: const Text("Import"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Clear All Data?"),
        content: const Text("This will delete all subjects, faculties, and timetable entries. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete All"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _service.clearAllData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("All data cleared.")));
        _loadData();
      }
    }
  }
}

