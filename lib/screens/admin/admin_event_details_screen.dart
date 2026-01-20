import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import 'admin_create_event_screen.dart';

class AdminEventDetailsScreen extends StatefulWidget {
  final Event event;

  const AdminEventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<AdminEventDetailsScreen> createState() => _AdminEventDetailsScreenState();
}

class _AdminEventDetailsScreenState extends State<AdminEventDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    // Re-fetch event from service to get latest updates
    final eventService = Provider.of<EventService>(context);
    final currentEvent = eventService.events.firstWhere((e) => e.id == widget.event.id, orElse: () => widget.event);

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(currentEvent.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminCreateEventScreen(event: currentEvent)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share functionality (CSV Export trigger)
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Exporting CSV...')));
              // eventService.exportRegistrationsCsv(currentEvent.id);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Registrations'),
            Tab(text: 'Waitlist & Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(currentEvent),
          _buildRegistrationsTab(currentEvent),
          _buildFeedbackTab(currentEvent),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Open Scanner or Check-in Dialog
          _showCheckInDialog(context, currentEvent);
        },
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Check-in'),
      ),
    );
  }

  Widget _buildOverviewTab(Event event) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatCard('Total Registrations', '${event.registrations.length}', Icons.people, Colors.blue),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStatCard('Confirmed', '${event.spotsTaken}', Icons.check_circle, Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _buildStatCard('Waitlist', '${event.waitlistCount}', Icons.timer, Colors.orange)),
          ],
        ),
        const SizedBox(height: 24),
        _buildSectionHeader('Broadcast Announcement'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Send push notification to all attendees', style: TextStyle(color: Colors.white54)),
              const SizedBox(height: 12),
              TextFormField(
                decoration: const InputDecoration(
                  hintText: 'Message (e.g., Venue changed to Hall B)',
                  filled: true,
                  fillColor: Colors.black12,
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Broadcast Sent!')));
                },
                icon: const Icon(Icons.send),
                label: const Text('Send Broadcast'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (event.scannerPin != null) ...[
          _buildSectionHeader('Volunteer Access'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.purple.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock_open, color: Colors.purple),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Scanner PIN', style: TextStyle(color: Colors.white70)),
                    Text(
                      event.scannerPin!,
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildRegistrationsTab(Event event) {
    if (event.registrations.isEmpty) {
      return const Center(child: Text('No registrations yet', style: TextStyle(color: Colors.white54)));
    }

    // Filter only confirmed/attended
    final relevantRegs = event.registrations.where((r) => r.status == RegistrationStatus.confirmed || r.status == RegistrationStatus.attended).toList();
    
    return ListView.builder(
      itemCount: relevantRegs.length,
      itemBuilder: (context, index) {
        final reg = relevantRegs[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: reg.hasAttended ? Colors.green : Colors.grey,
            child: Icon(reg.hasAttended ? Icons.check : Icons.person, color: Colors.white),
          ),
          title: Text(reg.studentName, style: const TextStyle(color: Colors.white)),
          subtitle: Text(reg.studentId, style: const TextStyle(color: Colors.white54)),
          trailing: reg.hasAttended
             ? const Chip(label: Text('Attended', style: TextStyle(fontSize: 10)), backgroundColor: Colors.green)
             : IconButton(
               icon: const Icon(Icons.check_circle_outline, color: Colors.white54),
               onPressed: () {
                 Provider.of<EventService>(context, listen: false).checkInUser(event.id, reg.registrationId);
               },
             ),
        );
      },
    );
  }

  Widget _buildFeedbackTab(Event event) {
     return const Center(child: Text('Feedback & Waitlist coming soon', style: TextStyle(color: Colors.white54)));
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
        ],
      ),
    );
  }
  
  void _showCheckInDialog(BuildContext context, Event event) {
    final controller = TextEditingController();
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a2e),
        title: const Text('Manual Check-in', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter Student ID',
            hintStyle: TextStyle(color: Colors.white54),
            filled: true,
            fillColor: Colors.black12,
          ),
        ),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
               // Find registration by student ID
              final reg = event.registrations.firstWhere(
                (r) => r.studentId == controller.text.trim(), 
                orElse: () => EventRegistration(registrationId: '', studentId: '', studentName: '', timestamp: DateTime.now(), responses: {})
              );
              
              if (reg.registrationId.isNotEmpty) {
                 Provider.of<EventService>(context, listen: false).checkInUser(event.id, reg.registrationId);
                 Navigator.pop(ctx);
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checked in ${reg.studentName}')));
              } else {
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student not registered!')));
              }
            },
            child: const Text('Check In'),
          ),
        ],
      )
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}
