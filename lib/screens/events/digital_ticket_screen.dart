import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import '../../services/supabase_service.dart';


class DigitalTicketScreen extends StatelessWidget {
  final Event event;

  const DigitalTicketScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get current registration
    final authService = Provider.of<AuthService>(context, listen: false);
    final eventService = Provider.of<EventService>(context); // Listen to updates
    final studentId = authService.currentUser?.enrollment ?? 'guest';
    
    // Refresh the specific event from service
    final currentEvent = eventService.events.firstWhere((e) => e.id == event.id, orElse: () => event);
    
    final registration = eventService.getUserRegistration(currentEvent.id, studentId);

    if (registration == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: const Center(child: Text("Ticket not found", style: TextStyle(color: Colors.white))),
      );
    }
    
    final isWaitlist = registration.status == RegistrationStatus.waitlist;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('My Ticket'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
               // Implement share ticket image logic later
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share Ticket coming soon!')));
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Ticket Card using Stack for visuals
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))
                ],
              ),
              child: Column(
                children: [
                  // Header Image or Gradient
                  Container(
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      image: currentEvent.imageUrl != null 
                        ? DecorationImage(image: NetworkImage(currentEvent.imageUrl!), fit: BoxFit.cover) 
                        : null,
                    ),
                    child: Center(
                      child: Text(
                        currentEvent.title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                           color: Colors.white, 
                           fontSize: 24, 
                           fontWeight: FontWeight.bold,
                           shadows: [Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)]
                        ),
                      ),
                    ),
                  ),
                  
                  // Info
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildInfoColumn('DATE', DateFormat('MMM dd, yyyy').format(currentEvent.eventDate)),
                            _buildInfoColumn('TIME', currentEvent.startTime),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             _buildInfoColumn('VENUE', currentEvent.venue),
                             _buildInfoColumn('STATUS', registration.status.toString().split('.').last.toUpperCase(),
                                isStatus: true,
                                color: isWaitlist ? Colors.orange : Colors.green
                             ),
                          ],
                        ),
                        const SizedBox(height: 30),
                        const Divider(thickness: 1, height: 1),
                        const SizedBox(height: 30),
                        
                        // QR Code
                        if (!isWaitlist) ...[
                          Text(
                            registration.studentName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          Text(registration.studentId, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 20),
                          QrImageView(
                            data: registration.registrationId,
                            version: QrVersions.auto,
                            size: 200.0,
                            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1a1a2e)),
                          ),
                          const SizedBox(height: 10),
                          const Text('Scan at entry', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ] else ...[
                          const Icon(Icons.timer, size: 80, color: Colors.orange),
                          const SizedBox(height: 20),
                          const Text('You are on the Waitlist', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          const Text('We will notify you if a spot opens up.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Post-Event Actions
            if (registration.hasAttended) ...[
              if (currentEvent.requiresCertificate)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                         // Download Certificate Logic
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading Certificate...')));
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download Certificate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                
               const SizedBox(height: 16),
               if (currentEvent.enableFeedback && registration.feedbackRating == null)
                 SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                       // Open Event Feedback Dialog
                       _showEventFeedbackDialog(context, currentEvent, registration);
                    },
                    icon: const Icon(Icons.star),
                    label: const Text('Leave Feedback'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber,
                      side: const BorderSide(color: Colors.amber),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value, {bool isStatus = false, Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
             fontWeight: FontWeight.bold, 
             fontSize: 16, 
             color: color ?? Colors.black87
          ),
        ),
      ],
    );
  }
  
  void _showEventFeedbackDialog(BuildContext context, Event event, EventRegistration registration) {
     double rating = 5.0;
     final commentController = TextEditingController();
     
     showDialog(
       context: context, 
       builder: (ctx) => StatefulBuilder(
         builder: (context, setDialogState) => AlertDialog( 
            backgroundColor: const Color(0xFF1a1a2e),
            title: const Text('Event Feedback', style: TextStyle(color: Colors.white)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('How was your experience?', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 30,
                      ),
                      onPressed: () => setDialogState(() => rating = index + 1.0),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Any comments? (Optional)',
                    hintStyle: TextStyle(color: Colors.white54),
                    filled: true,
                    fillColor: Colors.black12,
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Thank you for your feedback!')));
                },
                child: const Text('Submit'),
              ),
            ],
         ),
       )
     );
  }
}
