import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../services/supabase_service.dart';

class AdminRoleManagerScreen extends StatefulWidget {
  const AdminRoleManagerScreen({super.key});

  @override
  State<AdminRoleManagerScreen> createState() => _AdminRoleManagerScreenState();
}

class _AdminRoleManagerScreenState extends State<AdminRoleManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _moderators = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchModerators();
    });
  }

  Future<void> _fetchModerators() async {
    setState(() => _isLoading = true);
    final mods = await Provider.of<SupabaseService>(context, listen: false).fetchModerators();
    if (mounted) {
      setState(() {
        _moderators = mods;
        _isLoading = false;
      });
    }
  }

  Future<void> _addModerator() async {
    final enrollmentController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Add Event Moderator', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter the enrollment number of the student you want to make a moderator.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: enrollmentController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enrollment No.',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final enrollment = enrollmentController.text.trim();
              if (enrollment.isNotEmpty) {
                Navigator.pop(ctx);
                try {
                  setState(() => _isLoading = true);
                  await Provider.of<SupabaseService>(context, listen: false)
                      .assignRole(enrollment, 'event_moderator');
                  
                  if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Moderator Added Successfully')),
                    );
                    _fetchModerators();
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() => _isLoading = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              }
            },
            child: const Text('Add Role'),
          ),
        ],
      ),
    );
  }

  Future<void> _removeModerator(String enrollment) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Remove Role?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to remove moderator access for $enrollment?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
             onPressed: () => Navigator.pop(ctx, true), 
             child: const Text('Remove', style: TextStyle(color: Colors.redAccent))
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        await Provider.of<SupabaseService>(context, listen: false).removeRole(enrollment);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Role Removed')));
          _fetchModerators();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Manage Roles', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: const Color(0xFF0F172A).withOpacity(0.8)),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : _moderators.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 80, color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 16),
                        Text(
                          'No active moderators',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 80),
                    itemCount: _moderators.length,
                    itemBuilder: (context, index) {
                      final mod = _moderators[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                            child: const Icon(Icons.person, color: Colors.cyanAccent),
                          ),
                          title: Text(mod['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('${mod['enrollment']} • ${mod['branch']}', style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                            onPressed: () => _removeModerator(mod['enrollment']),
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addModerator,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_moderator),
        label: const Text('Add Moderator'),
      ),
    );
  }
}
