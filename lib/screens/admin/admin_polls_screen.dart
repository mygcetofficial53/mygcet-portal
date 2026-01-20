import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/supabase_service.dart';

class AdminPollsScreen extends StatefulWidget {
  const AdminPollsScreen({super.key});

  @override
  State<AdminPollsScreen> createState() => _AdminPollsScreenState();
}

class _AdminPollsScreenState extends State<AdminPollsScreen> {
  Map<String, dynamic>? _activePoll;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPoll();
  }

  Future<void> _loadPoll() async {
    setState(() => _isLoading = true);
    final data = await Provider.of<SupabaseService>(context, listen: false).fetchActivePoll();
    if (mounted) setState(() {
      _activePoll = data;
      _isLoading = false;
    });
  }

  void _confirmDelete(String pollId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Delete Poll?', style: TextStyle(color: Colors.white)),
        content: const Text('This will remove the active poll and all votes.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await Provider.of<SupabaseService>(context, listen: false).deletePoll(pollId);
              _loadPoll();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreatePollDialog() {
    final questionCtrl = TextEditingController();
    final option1Ctrl = TextEditingController();
    final option2Ctrl = TextEditingController();
    final option3Ctrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('New Poll', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: questionCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Question', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: option1Ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Option 1', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: option2Ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Option 2', labelStyle: TextStyle(color: Colors.white70)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: option3Ctrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Option 3 (Optional)', labelStyle: TextStyle(color: Colors.white70)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (questionCtrl.text.isEmpty || option1Ctrl.text.isEmpty || option2Ctrl.text.isEmpty) return;
              
              final options = [option1Ctrl.text.trim(), option2Ctrl.text.trim()];
              if (option3Ctrl.text.isNotEmpty) options.add(option3Ctrl.text.trim());

              await Provider.of<SupabaseService>(context, listen: false).createPoll(
                questionCtrl.text.trim(), 
                options
              );
              if (mounted) {
                Navigator.pop(ctx);
                _loadPoll();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Launch Poll', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF101014),
      appBar: AppBar(
        title: const Text('Manage Polls', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _activePoll == null 
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.poll_outlined, size: 64, color: Colors.white24),
                      const SizedBox(height: 16),
                      const Text('No active poll', style: TextStyle(color: Colors.white54)),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _showCreatePollDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New Poll'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Card(
                      color: const Color(0xFF1E293B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Chip(
                                  label: Text('ACTIVE NOW', style: TextStyle(color: Colors.white, fontSize: 10)),
                                  backgroundColor: Colors.green,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _confirmDelete(_activePoll!['id']),
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _activePoll!['question'],
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 24),
                            ..._buildOptions(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  List<Widget> _buildOptions() {
    final options = List<dynamic>.from(_activePoll!['options'] ?? []);
    final counts = Map<String, int>.from(_activePoll!['vote_counts']?.map((k, v) => MapEntry(k.toString(), v)) ?? {});
    final totalVotes = _activePoll!['total_votes'] as int? ?? 0;

    return List.generate(options.length, (index) {
      final option = options[index];
      final count = counts[index.toString()] ?? 0;
      final percentage = totalVotes == 0 ? 0.0 : (count / totalVotes);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(option, style: const TextStyle(color: Colors.white70)),
                Text('${(percentage * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.white10,
              color: const Color(0xFF8B5CF6),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 4),
            Text('$count votes', style: const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      );
    });
  }
}
