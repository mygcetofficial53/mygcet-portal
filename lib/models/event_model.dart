import 'dart:convert';
import 'package:flutter/material.dart';

enum EventStatus { upcoming, ongoing, completed, cancelled }
enum RegistrationStatus { confirmed, waitlist, cancelled, attended }
enum EventFieldType { text, number, dropdown, checkbox, date }

/// Represents a custom field in the event registration form
class EventField {
  final String id;
  final String name;
  final EventFieldType type;
  final bool isRequired;
  final List<String>? options; // For dropdowns

  EventField({
    required this.id,
    required this.name,
    required this.type,
    this.isRequired = false,
    this.options,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.toString(),
        'isRequired': isRequired,
        'options': options,
      };

  factory EventField.fromJson(Map<String, dynamic> json) => EventField(
        id: json['id'],
        name: json['name'],
        type: EventFieldType.values.firstWhere(
            (e) => e.toString() == json['type'],
            orElse: () => EventFieldType.text),
        isRequired: json['isRequired'] ?? false,
        options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      );
}

/// Represents a user's registration for an event
class EventRegistration {
  final String registrationId; // Unique UUID
  final String studentId;
  final String studentName; // Cache name for easy export
  final DateTime timestamp;
  final RegistrationStatus status;
  final Map<String, dynamic> responses; // Answers to custom fields
  
  // Team details
  final String? teamName;
  final List<String>? teamMembers; // List of enrollment numbers

  // Attendance & Post-Event
  final bool hasAttended;
  final DateTime? checkInTime;
  final double? feedbackRating;
  final String? feedbackComment;
  final String? certificateUrl; // Path to generated PDF

  EventRegistration({
    required this.registrationId,
    required this.studentId,
    required this.studentName,
    required this.timestamp,
    required this.responses,
    this.status = RegistrationStatus.confirmed,
    this.teamName,
    this.teamMembers,
    this.hasAttended = false,
    this.checkInTime,
    this.feedbackRating,
    this.feedbackComment,
    this.certificateUrl,
  });

  EventRegistration copyWith({
    RegistrationStatus? status,
    bool? hasAttended,
    DateTime? checkInTime,
    double? feedbackRating,
    String? feedbackComment,
    String? certificateUrl,
  }) {
    return EventRegistration(
      registrationId: registrationId,
      studentId: studentId,
      studentName: studentName,
      timestamp: timestamp,
      responses: responses,
      status: status ?? this.status,
      teamName: teamName,
      teamMembers: teamMembers,
      hasAttended: hasAttended ?? this.hasAttended,
      checkInTime: checkInTime ?? this.checkInTime,
      feedbackRating: feedbackRating ?? this.feedbackRating,
      feedbackComment: feedbackComment ?? this.feedbackComment,
      certificateUrl: certificateUrl ?? this.certificateUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'registrationId': registrationId,
        'studentId': studentId,
        'studentName': studentName,
        'timestamp': timestamp.toIso8601String(),
        'status': status.toString(),
        'responses': responses,
        'teamName': teamName,
        'teamMembers': teamMembers,
        'hasAttended': hasAttended,
        'checkInTime': checkInTime?.toIso8601String(),
        'feedbackRating': feedbackRating,
        'feedbackComment': feedbackComment,
        'certificateUrl': certificateUrl,
      };

  factory EventRegistration.fromJson(Map<String, dynamic> json) => EventRegistration(
        registrationId: json['registrationId'],
        studentId: json['studentId'],
        studentName: json['studentName'] ?? 'Unknown',
        timestamp: DateTime.parse(json['timestamp']),
        status: RegistrationStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
            orElse: () => RegistrationStatus.confirmed),
        responses: Map<String, dynamic>.from(json['responses'] ?? {}),
        teamName: json['teamName'],
        teamMembers: (json['teamMembers'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
        hasAttended: json['hasAttended'] ?? false,
        checkInTime: json['checkInTime'] != null ? DateTime.parse(json['checkInTime']) : null,
        feedbackRating: json['feedbackRating']?.toDouble(),
        feedbackComment: json['feedbackComment'],
        certificateUrl: json['certificateUrl'],
      );
}

/// Superior Event Model
class Event {
  final String id;
  final String title;
  final String description;
  final String category;
  final DateTime eventDate;
  final String startTime;
  final String endTime;
  final String venue;
  final int maxParticipants;
  final String? imageUrl;
  final bool isActive;
  final DateTime createdAt;
  
  // Advanced Features
  final List<EventField> formFields;
  final List<EventRegistration> registrations;
  
  // Team Settings
  final bool isTeamEvent;
  final int minTeamSize;
  final int maxTeamSize;

  // Waitlist
  final bool allowWaitlist;
  final int waitlistCapacity;

  // Certificates & Gamification
  final bool requiresCertificate;
  final String? certificateTemplateId;
  final int xpPoints;
  
  // Volunteer Access
  final String? scannerPin; // Simple PIN for volunteers to login and scan

  // Feedback
  final bool enableFeedback;

  // Content Verification
  final String status; // 'pending', 'approved', 'rejected'
  final String? createdBy; // Enrollment of the creator (if moderator)

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.eventDate,
    required this.startTime,
    required this.endTime,
    required this.venue,
    required this.maxParticipants,
    this.imageUrl,
    this.isActive = true,
    this.status = 'approved', // Default to approved for backward compat
    this.createdBy,
    DateTime? createdAt,
    this.formFields = const [],
    this.registrations = const [],
    this.isTeamEvent = false,
    this.minTeamSize = 1,
    this.maxTeamSize = 1,
    this.allowWaitlist = false,
    this.waitlistCapacity = 0,
    this.requiresCertificate = false,
    this.certificateTemplateId,
    this.xpPoints = 0,
    this.scannerPin,
    this.enableFeedback = false,
  }) : createdAt = createdAt ?? DateTime.now();

  int get spotsTaken => registrations.where((r) => r.status == RegistrationStatus.confirmed).length;
  int get spotsLeft => maxParticipants - spotsTaken;
  bool get isFull => spotsLeft <= 0;
  bool get isUpcoming => eventDate.isAfter(DateTime.now());

  // Waitlist logic
  int get waitlistCount => registrations.where((r) => r.status == RegistrationStatus.waitlist).length;
  bool get isWaitlistFull => allowWaitlist && waitlistCount >= waitlistCapacity;
  bool get canRegister => !isFull || (!isWaitlistFull && allowWaitlist);
  
  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'event_date': eventDate.toIso8601String(), // Snake case for Supabase
        'eventDate': eventDate.toIso8601String(),   // Camel case for Local
        'start_time': startTime,
        'startTime': startTime,
        'end_time': endTime,
        'endTime': endTime,
        'venue': venue,
        'max_participants': maxParticipants,
        'maxParticipants': maxParticipants,
        'image_url': imageUrl,
        'imageUrl': imageUrl,
        'is_active': isActive,
        'isActive': isActive,
        'status': status,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        // Complex fields omitted from top-level Supabase insert usually
        // But kept here for local storage compat
        'formFields': formFields.map((e) => e.toJson()).toList(),
        'registrations': registrations.map((e) => e.toJson()).toList(),
        'isTeamEvent': isTeamEvent,
        'minTeamSize': minTeamSize,
        'maxTeamSize': maxTeamSize,
        'allowWaitlist': allowWaitlist,
        'waitlistCapacity': waitlistCapacity,
        'requiresCertificate': requiresCertificate,
        'certificateTemplateId': certificateTemplateId,
        'xpPoints': xpPoints,
        'scannerPin': scannerPin,
        'enableFeedback': enableFeedback,
      };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        description: json['description'] ?? '',
        category: json['category'] ?? 'General',
        // Support both snake_case (Supabase) and camelCase (Local)
        eventDate: DateTime.tryParse(json['event_date'] ?? json['eventDate'] ?? '') ?? DateTime.now(),
        startTime: json['start_time'] ?? json['startTime'] ?? '09:00 AM',
        endTime: json['end_time'] ?? json['endTime'] ?? '05:00 PM',
        venue: json['venue'] ?? '',
        maxParticipants: json['max_participants'] ?? json['maxParticipants'] ?? 100,
        imageUrl: json['image_url'] ?? json['imageUrl'],
        isActive: json['is_active'] ?? json['isActive'] ?? true,
        status: json['status'] ?? 'approved',
        createdBy: json['created_by'] ?? json['createdBy'],
        createdAt: DateTime.tryParse(json['created_at'] ?? json['createdAt'] ?? '') ?? DateTime.now(),
        
        formFields: (json['formFields'] as List<dynamic>?)
                ?.map((e) => EventField.fromJson(e))
                .toList() ??
            [],
        registrations: (json['registrations'] as List<dynamic>?)
                ?.map((e) => EventRegistration.fromJson(e))
                .toList() ??
            [],
        isTeamEvent: json['isTeamEvent'] ?? false,
        minTeamSize: json['minTeamSize'] ?? 1,
        maxTeamSize: json['maxTeamSize'] ?? 1,
        allowWaitlist: json['allowWaitlist'] ?? false,
        waitlistCapacity: json['waitlistCapacity'] ?? 0,
        requiresCertificate: json['requiresCertificate'] ?? false,
        certificateTemplateId: json['certificateTemplateId'],
        xpPoints: json['xpPoints'] ?? 0,
        scannerPin: json['scannerPin'],
        enableFeedback: json['enableFeedback'] ?? false,
      );

  Event copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    String? venue,
    int? maxParticipants,
    String? imageUrl,
    bool? isActive,
    String? status,
    String? createdBy,
    List<EventField>? formFields,
    List<EventRegistration>? registrations,
    bool? isTeamEvent,
    int? minTeamSize,
    int? maxTeamSize,
    bool? allowWaitlist,
    int? waitlistCapacity,
    bool? requiresCertificate,
    String? certificateTemplateId,
    int? xpPoints,
    String? scannerPin,
    bool? enableFeedback,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      venue: venue ?? this.venue,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt,
      formFields: formFields ?? this.formFields,
      registrations: registrations ?? this.registrations,
      isTeamEvent: isTeamEvent ?? this.isTeamEvent,
      minTeamSize: minTeamSize ?? this.minTeamSize,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      allowWaitlist: allowWaitlist ?? this.allowWaitlist,
      waitlistCapacity: waitlistCapacity ?? this.waitlistCapacity,
      requiresCertificate: requiresCertificate ?? this.requiresCertificate,
      certificateTemplateId: certificateTemplateId ?? this.certificateTemplateId,
      xpPoints: xpPoints ?? this.xpPoints,
      scannerPin: scannerPin ?? this.scannerPin,
      enableFeedback: enableFeedback ?? this.enableFeedback,
    );
  }
}

class EventCategories {
  static const List<String> all = [
    'Technical', 'Cultural', 'Sports', 'Workshop', 'Seminar', 'Hackathon', 'Competition', 'Fest', 'Other'
  ];
}
