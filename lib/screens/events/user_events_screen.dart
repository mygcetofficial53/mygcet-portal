import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import 'event_registration_screen.dart';
import 'digital_ticket_screen.dart';

class UserEventsScreen extends StatefulWidget {
  const UserEventsScreen({Key? key}) : super(key: key);

  @override
  State<UserEventsScreen> createState() => _UserEventsScreenState();
}

class _UserEventsScreenState extends State<UserEventsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<EventService>(context, listen: false).loadEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: const Text('Events'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF8B5CF6),
          tabs: const [
            Tab(text: 'Explore'),
            Tab(text: 'My Tickets'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildExploreTab(),
          _buildMyTicketsTab(),
        ],
      ),
    );
  }

  Widget _buildExploreTab() {
    return Consumer<EventService>(
      builder: (context, eventService, _) {
        final events = eventService.activeEvents;
        
        if (eventService.isLoading) return const Center(child: CircularProgressIndicator());
        if (events.isEmpty) return const Center(child: Text('No upcoming events', style: TextStyle(color: Colors.white70)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            return _buildEventCard(events[index], isTicket: false);
          },
        );
      },
    );
  }

  Widget _buildMyTicketsTab() {
    return Consumer<EventService>(
      builder: (context, eventService, _) {
        final authService = Provider.of<AuthService>(context, listen: false);
        final user = authService.currentUser;
        
        if (user == null) return const Center(child: Text('Please log in', style: TextStyle(color: Colors.white)));

        final myEvents = eventService.events.where((e) => 
            eventService.isUserRegistered(e.id, user.enrollment)
        ).toList();

        if (myEvents.isEmpty) return const Center(child: Text('No tickets yet', style: TextStyle(color: Colors.white70)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myEvents.length,
          itemBuilder: (context, index) {
            return _buildEventCard(myEvents[index], isTicket: true);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Event event, {required bool isTicket}) {
    return Card(
      color: Colors.white.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          if (isTicket) {
            Navigator.push(context, MaterialPageRoute(builder: (_) => DigitalTicketScreen(event: event)));
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => EventRegistrationScreen(event: event)));
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image header (placeholder color if no image)
            Container(
              height: 100,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade900, Colors.purple.shade900],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight
                ),
                image: event.imageUrl != null 
                  ? DecorationImage(image: NetworkImage(event.imageUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: isTicket 
                ? Center(child: Icon(Icons.qr_code, color: Colors.white.withOpacity(0.5), size: 40))
                : null,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: Colors.white54, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('MMM dd • ').format(event.eventDate) + event.startTime,
                        style: const TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                      const Spacer(),
                      if (!isTicket && event.xpPoints > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                          child: Text('+${event.xpPoints} XP', style: const TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        )
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
