import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import 'dart:ui';

class AppFeedbackCard extends StatefulWidget {
  const AppFeedbackCard({super.key});

  @override
  State<AppFeedbackCard> createState() => _AppFeedbackCardState();
}

class _AppFeedbackCardState extends State<AppFeedbackCard> {
  bool _hasSubmitted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final enrollment = context.read<AuthService>().currentUser?.enrollment;
    if (enrollment != null) {
      final submitted = await context.read<SupabaseService>().hasUserSubmittedFeedback(enrollment);
      if (mounted) setState(() {
        _hasSubmitted = submitted;
        _isLoading = false;
      });
    }
  }

  void _showFeedbackDialog() {
    final enrollment = context.read<AuthService>().currentUser?.enrollment;
    if (enrollment == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('We value your opinion!', style: TextStyle(color: Colors.white)),
        content: const Text('Do you enjoy using GCET Tracker?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showFeedbackInput(context, enrollment); 
            },
            child: const Text('Not really'),
          ),
          ElevatedButton(
            onPressed: () {
               context.read<SupabaseService>().submitFeedback(enrollment: enrollment, liked: true);
               Navigator.pop(ctx);
               setState(() => _hasSubmitted = true);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Thank you for your feedback! ❤️')),
               );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Yes, I love it!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showFeedbackInput(BuildContext context, String enrollment) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Help us improve', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('What changes do you need?', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Type your suggestions...',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
               if (controller.text.trim().isNotEmpty) {
                 context.read<SupabaseService>().submitFeedback(
                   enrollment: enrollment, 
                   liked: false, 
                   message: controller.text.trim()
                 );
                 Navigator.pop(ctx);
                 if (mounted) setState(() => _hasSubmitted = true);
                 ScaffoldMessenger.of(context).showSnackBar(
                   const SnackBar(content: Text('Feedback submitted. We will look into it!')),
                 );
               }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    if (_hasSubmitted) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.greenAccent),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Thanks for your feedback! We are listening.',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _showFeedbackDialog,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.withOpacity(0.2), Colors.deepPurple.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.thumb_up_alt_outlined, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enjoying the App?',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let us know how we can improve.',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white30, size: 16),
          ],
        ),
      ),
    );
  }
}
