/// Study material model for GMS portal
class StudyMaterial {
  final String id;
  final String title;
  final String subjectCode;
  final String subjectName;
  final String type;
  final String uploadedBy;
  final String uploadedAt;
  final String? url;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.subjectCode,
    required this.subjectName,
    required this.type,
    required this.uploadedBy,
    required this.uploadedAt,
    this.url,
  });

  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      type: json['type'] ?? 'document',
      uploadedBy: json['uploaded_by'] ?? '',
      uploadedAt: json['uploaded_at'] ?? '',
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'type': type,
      'uploaded_by': uploadedBy,
      'uploaded_at': uploadedAt,
      'url': url,
    };
  }
}

/// Quiz model for GMS portal
class Quiz {
  final String id;
  final String title;
  final String subjectCode;
  final String subjectName;
  final String status;
  final int? score;
  final int? maxScore;
  final DateTime? startTime;
  final DateTime? endTime;
  final int? durationMinutes;
  final int? totalQuestions;

  Quiz({
    required this.id,
    required this.title,
    required this.subjectCode,
    required this.subjectName,
    required this.status,
    this.score,
    this.maxScore,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.totalQuestions,
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      status: json['status'] ?? 'completed',
      score: json['score'],
      maxScore: json['max_score'],
      startTime: json['start_time'] != null ? DateTime.parse(json['start_time']) : null,
      endTime: json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      durationMinutes: json['duration_minutes'],
      totalQuestions: json['total_questions'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'status': status,
      'score': score,
      'max_score': maxScore,
      'start_time': startTime?.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_minutes': durationMinutes,
      'total_questions': totalQuestions,
    };
  }
}

/// Library book model
class Book {
  final String id;
  final String title;
  final String author;
  final String issueDate;
  final String dueDate;
  final String status;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.issueDate,
    required this.dueDate,
    required this.status,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      issueDate: json['issue_date'] ?? '',
      dueDate: json['due_date'] ?? '',
      status: json['status'] ?? 'issued',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'issue_date': issueDate,
      'due_date': dueDate,
      'status': status,
    };
  }
}

/// Calendar event model
class CalendarEvent {
  final String id;
  final String title;
  final String date;
  final String description;
  final String type;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.date,
    required this.description,
    required this.type,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? 'academic',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'description': description,
      'type': type,
    };
  }
}

// Demo data generators for demo mode
class DemoData {
  static List<StudyMaterial> materials() {
    return [
      StudyMaterial(
        id: 'MAT001',
        title: 'Introduction to Software Engineering',
        subjectCode: 'CS501',
        subjectName: 'Software Engineering',
        type: 'PDF',
        uploadedBy: 'Dr. Rajesh Kumar',
        uploadedAt: '2024-12-15',
      ),
      StudyMaterial(
        id: 'MAT002',
        title: 'Database Normalization Notes',
        subjectCode: 'CS502',
        subjectName: 'Database Management Systems',
        type: 'PDF',
        uploadedBy: 'Prof. Anitha Reddy',
        uploadedAt: '2024-12-10',
      ),
      StudyMaterial(
        id: 'MAT003',
        title: 'OSI Model Presentation',
        subjectCode: 'CS503',
        subjectName: 'Computer Networks',
        type: 'PPT',
        uploadedBy: 'Dr. Suresh Naik',
        uploadedAt: '2024-12-08',
      ),
      StudyMaterial(
        id: 'MAT004',
        title: 'Process Scheduling Algorithms',
        subjectCode: 'CS504',
        subjectName: 'Operating Systems',
        type: 'PDF',
        uploadedBy: 'Prof. Venkat Rao',
        uploadedAt: '2024-12-05',
      ),
      StudyMaterial(
        id: 'MAT005',
        title: 'Neural Networks Tutorial',
        subjectCode: 'CS506',
        subjectName: 'Machine Learning',
        type: 'PDF',
        uploadedBy: 'Dr. Priya Sharma',
        uploadedAt: '2024-12-01',
      ),
    ];
  }

  static List<Quiz> quizzes() {
    return [
      Quiz(
        id: 'QUIZ001',
        title: 'Software Engineering Mid Sem Quiz',
        subjectCode: 'CS501',
        subjectName: 'Software Engineering',
        status: 'completed',
        score: 18,
        maxScore: 20,
      ),
      Quiz(
        id: 'QUIZ002',
        title: 'DBMS Unit Test 1',
        subjectCode: 'CS502',
        subjectName: 'Database Management Systems',
        status: 'completed',
        score: 15,
        maxScore: 20,
      ),
      Quiz(
        id: 'QUIZ003',
        title: 'Computer Networks Weekly Quiz',
        subjectCode: 'CS503',
        subjectName: 'Computer Networks',
        status: 'completed',
        score: 8,
        maxScore: 10,
      ),
      Quiz(
        id: 'QUIZ004',
        title: 'Operating Systems Practice Test',
        subjectCode: 'CS504',
        subjectName: 'Operating Systems',
        status: 'upcoming',
      ),
      Quiz(
        id: 'QUIZ005',
        title: 'AI Concepts Quiz',
        subjectCode: 'CS505',
        subjectName: 'Artificial Intelligence',
        status: 'upcoming',
      ),
    ];
  }

  static List<Book> books() {
    return [
      Book(
        id: 'BOOK001',
        title: 'Database System Concepts',
        author: 'Silberschatz, Korth & Sudarshan',
        issueDate: '2024-11-15',
        dueDate: '2024-12-30',
        status: 'issued',
      ),
      Book(
        id: 'BOOK002',
        title: 'Computer Networks',
        author: 'Andrew S. Tanenbaum',
        issueDate: '2024-12-01',
        dueDate: '2025-01-15',
        status: 'issued',
      ),
      Book(
        id: 'BOOK003',
        title: 'Introduction to Algorithms',
        author: 'Thomas H. Cormen',
        issueDate: '2024-10-01',
        dueDate: '2024-12-01',
        status: 'returned',
      ),
    ];
  }

  static List<CalendarEvent> events() {
    return [
      CalendarEvent(
        id: 'EVT001',
        title: 'Mid Semester Exams Begin',
        date: '2025-01-15',
        description: 'Mid semester examinations for all branches',
        type: 'exam',
      ),
      CalendarEvent(
        id: 'EVT002',
        title: 'Republic Day Holiday',
        date: '2025-01-26',
        description: 'National Holiday - College Closed',
        type: 'holiday',
      ),
      CalendarEvent(
        id: 'EVT003',
        title: 'Technical Symposium',
        date: '2025-02-10',
        description: 'Annual technical fest TECHNOVATE 2025',
        type: 'event',
      ),
      CalendarEvent(
        id: 'EVT004',
        title: 'Project Submission Deadline',
        date: '2025-02-28',
        description: 'Final submission for mini projects',
        type: 'academic',
      ),
      CalendarEvent(
        id: 'EVT005',
        title: 'End Semester Exams',
        date: '2025-04-01',
        description: 'End semester examinations begin',
        type: 'exam',
      ),
    ];
  }
}
