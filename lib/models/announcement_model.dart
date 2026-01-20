/// Announcement model for displaying announcements on dashboard
class Announcement {
  final String id;
  final String title;
  final String message;
  final AnnouncementType type;
  final DateTime date;
  final bool isRead;
  final String? actionUrl;

  const Announcement({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.date,
    this.isRead = false,
    this.actionUrl,
  });

  Announcement copyWith({
    String? id,
    String? title,
    String? message,
    AnnouncementType? type,
    DateTime? date,
    bool? isRead,
    String? actionUrl,
  }) {
    return Announcement(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      date: date ?? this.date,
      isRead: isRead ?? this.isRead,
      actionUrl: actionUrl ?? this.actionUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name,
      'date': date.toIso8601String(),
      'isRead': isRead,
      'actionUrl': actionUrl,
    };
  }

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      type: AnnouncementType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AnnouncementType.info,
      ),
      date: DateTime.parse(json['date'] as String),
      isRead: json['isRead'] as bool? ?? false,
      actionUrl: json['actionUrl'] as String?,
    );
  }
}

/// Types of announcements with associated styling
enum AnnouncementType {
  info,     // Blue - General information
  success,  // Green - Good news, achievements
  warning,  // Orange - Important notices
  alert,    // Red - Urgent alerts
  event,    // Purple - Events and activities
}
