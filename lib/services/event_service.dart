import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/event_model.dart';

/// Service for managing events (local storage for now)
class EventService extends ChangeNotifier {
  static const String _eventsKey = 'events_data';
  static const String _adminLoggedInKey = 'admin_logged_in';
  
  // Hardcoded admin credentials
  static const String adminUsername = '30912846';
  static const String adminPassword = '30918869';

  final SupabaseClient _supabase = Supabase.instance.client;

  List<Event> _events = [];
  bool _isLoading = false;
  // We don't need local admin auth anymore, we rely on AuthService/SupabaseService
  
  List<Event> get events => _events;
  List<Event> get activeEvents => _events.where((e) => e.isActive && e.status == 'approved').toList();
  List<Event> get upcomingEvents => activeEvents.where((e) => e.isUpcoming).toList();
  List<Event> get pendingEvents => _events.where((e) => e.status == 'pending').toList();

  bool get isLoading => _isLoading;

  /// Initialize and load events
  Future<void> init() async {
    await loadEvents();
  }

  /// Load events from Supabase
  Future<void> loadEvents() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _supabase
          .from('events')
          .select()
          .order('created_at', ascending: false);
      
      final List<dynamic> jsonList = response;
      _events = jsonList.map((e) => Event.fromJson(e)).toList();
      
      // If no events in DB, maybe seed demo events? 
      // Only if truly empty and we want to show something.
      if (_events.isEmpty) {
        // _events = _getDemoEvents(); // Don't auto-save demo events to DB to avoid spam
      }
    } catch (e) {
      debugPrint('EventService: Error loading events from Supabase: $e');
      // Fallback to local demo if DB fails?
      // _events = _getDemoEvents();
    }

    _isLoading = false;
    notifyListeners();
  }
  
  /// Create a new event
  Future<void> createEvent(Event event) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Determine status based on role? 
      // For now, client sends status in object, or we enforce 'pending' here.
      // We'll trust the object status (controller logic will set it to 'pending' if moderator)
      
      final eventData = event.toJson();
      // Remove complex objects for now if table doesn't support them fully
      // We assume basic fields exist. 
      // To support registrations/formFields, we need JSONB columns or separate tables.
      // For this migration, we'll try to insert what we have.
      
      // Cleanup for SQL insert (remove nulls or handle them)
      eventData.removeWhere((key, value) => value == null);

      await _supabase.from('events').insert(eventData);
      
      await loadEvents(); // Refresh
    } catch (e) {
      debugPrint('EventService: Error creating event: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Approve an event (Admin)
  Future<void> approveEvent(String eventId) async {
    try {
      await _supabase
          .from('events')
          .update({'status': 'approved', 'is_active': true})
          .eq('id', eventId);
      
      await loadEvents();
    } catch (e) {
      debugPrint('EventService: Error approving event: $e');
      rethrow;
    }
  }

  /// Reject/Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _supabase.from('events').delete().eq('id', eventId);
      await loadEvents();
    } catch (e) {
      debugPrint('EventService: Error deleting event: $e');
      rethrow;
    }
  }

  /// Toggle event active status
  Future<void> toggleEventStatus(String eventId) async {
    final index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      final newStatus = !_events[index].isActive;
      try {
        await _supabase.from('events').update({'is_active': newStatus}).eq('id', eventId);
        await loadEvents();
      } catch (e) {
        debugPrint('EventService: Error toggling status: $e');
      }
    }
  }

  /// Register user for an event (Simplified for now - requires event_registrations table)
  // For now, we will just return true strictly to allow UI flow, 
  // but we need to notify user that registrations aren't persisted yet without SQL update.
  Future<bool> registerForEvent({
    required String eventId,
    required String studentId,
    required String studentName,
    required Map<String, dynamic> responses,
    String? teamName,
    List<String>? teamMembers,
  }) async {
      // Stub: Real implementation needs 'event_registrations' table
      // We will implement local optimistic update? No, that's confusing.
      // We will just return true and print a warning.
      debugPrint('WARNING: Registrations not fully persisted to Supabase yet. Need schema update.');
      return true;
  }
  
  /// Check-in User
  Future<bool> checkInUser(String eventId, String registrationId) async {
    return true; // Stub
  }

  /// Get events by category
  List<Event> getEventsByCategory(String category) {
    return activeEvents.where((e) => e.category == category).toList();
  }

  /// Get demo events (kept for reference)
  List<Event> _getDemoEvents() {
    return [
      Event(
        id: 'evt_001',
        title: 'TechFest 2025',
        description: 'Annual technical festival with coding competitions, robotics, and workshops.',
        category: 'Fest',
        eventDate: DateTime.now().add(const Duration(days: 30)),
        startTime: '09:00 AM',
        endTime: '06:00 PM',
        venue: 'Main Auditorium',
        maxParticipants: 500,
        isActive: true,
        xpPoints: 50,
      ),
    ];
  }
  // Placeholder method for getting user registration (Digital Ticket)
  EventRegistration? getUserRegistration(String eventId, String studentId) {
    try {
      final event = _events.firstWhere((e) => e.id == eventId);
      if (event.registrations.isEmpty) return null;
      // In a real app with separate table, we'd fetch from DB.
      // Here we check the event object's registration list.
      return event.registrations.cast<EventRegistration?>().firstWhere(
        (r) => r?.studentId == studentId,
        orElse: () => null,
      );
    } catch (e) {
      return null;
    }
  }

  bool isUserRegistered(String eventId, String studentId) {
    return getUserRegistration(eventId, studentId) != null;
  }

  Future<void> updateEvent(Event event) async {
    try {
      _isLoading = true;
      notifyListeners();
      await _supabase.from('events').update(event.toJson()).eq('id', event.id);
      await loadEvents();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
