import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import '../../services/supabase_service.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedType = 'info';
  String? _selectedTargetBranch; // Null = All
  final List<String> _types = ['info', 'warning', 'success', 'event'];
  final List<String> _branches = ['All Departments', 'CP', 'IT', 'ME', 'EE', 'MC', 'EC'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupabaseService>().fetchNotifications();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitNotification() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      await context.read<SupabaseService>().createNotification(
        title: _titleController.text.trim(),
        message: _messageController.text.trim(),
        type: _selectedType,
        targetBranch: _selectedTargetBranch == 'All Departments' ? null : _selectedTargetBranch,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification Post Created!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _selectedType = 'info';
          _selectedTargetBranch = null;
        });
        Navigator.pop(context);
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddNotificationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              top: 30,
              left: 24,
              right: 24,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'New Notification',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(controller: _titleController, label: 'Title', icon: Icons.title),
                  const SizedBox(height: 16),
                  _buildTextField(controller: _messageController, label: 'Message', icon: Icons.message, maxLines: 3),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildDropdown()),
                      const SizedBox(width: 12),
                      Expanded(child: _buildBranchDropdown()),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 8,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.5),
                    ),
                    child: const Text('POST NOTIFICATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
      ),
      validator: (v) => v?.isEmpty == true ? 'Required' : null,
    );
  }

  // ... (keep _buildTextField)

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedType,
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Type',
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.category, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: _types.map((t) => DropdownMenuItem(
        value: t, 
        child: Row(
          children: [
            Icon(_getIconForType(t), color: _getColorForType(t), size: 18),
            const SizedBox(width: 8),
            Text(t.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        )
      )).toList(),
      onChanged: (v) => setState(() => _selectedType = v!),
    );
  }

  Widget _buildBranchDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedTargetBranch ?? 'All Departments',
      dropdownColor: const Color(0xFF1E293B),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: 'Target',
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: const Icon(Icons.people_alt, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
      items: _branches.map((b) => DropdownMenuItem(
        value: b, 
        child: Text(b, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      )).toList(),
      onChanged: (v) => setState(() => _selectedTargetBranch = v),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
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
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Consumer<SupabaseService>(
          builder: (context, service, child) {
            if (service.isLoading && service.notifications.isEmpty) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
            }

            if (service.error != null) {
              return Center(child: Text('Error: ${service.error}', style: const TextStyle(color: Colors.redAccent)));
            }

            if (service.notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_off_outlined, size: 80, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    Text(
                      'No active notifications',
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => service.fetchNotifications(),
              color: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFF1E293B),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 20),
                itemCount: service.notifications.length,
                itemBuilder: (context, index) {
                  final notif = service.notifications[index];
                  return Dismissible(
                    key: Key(notif['id'].toString()),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(20)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white, size: 28),
                    ),
                    onDismissed: (_) {
                      service.deleteNotification(notif['id']);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification Deleted'), backgroundColor: Colors.red, duration: Duration(seconds: 2)),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _getColorForType(notif['type']).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(_getIconForType(notif['type']), color: _getColorForType(notif['type'])),
                            ),
                            title: Text(notif['title'] ?? 'No Title', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(notif['message'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7))),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  notif['type']?.toUpperCase() ?? 'INFO',
                                  style: TextStyle(fontSize: 10, color: _getColorForType(notif['type']), fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                const SizedBox(height: 4),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => service.deleteNotification(notif['id']),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddNotificationSheet,
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('NEW POST', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'warning': return Colors.orangeAccent;
      case 'success': return Colors.greenAccent;
      case 'event': return Colors.purpleAccent;
      default: return Colors.blueAccent;
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'warning': return Icons.warning_amber_rounded;
      case 'success': return Icons.check_circle_outline;
      case 'event': return Icons.event;
      default: return Icons.info_outline;
    }
  }
}
