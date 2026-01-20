class SubjectAttendance {
  final String subjectCode;
  final String subjectName;
  final int totalClasses;
  final int attendedClasses;
  final double percentage;
  final String type; // 'Theory' or 'Lab'
  final String facultyName;

  SubjectAttendance({
    required this.subjectCode,
    required this.subjectName,
    required this.totalClasses,
    required this.attendedClasses,
    required this.percentage,
    this.type = 'Theory',
    this.facultyName = '',
  });

  /// Calculate classes needed to reach 75% attendance
  int get classesNeededFor75 {
    if (percentage >= 75) return 0;
    // Formula: (attended + x) / (total + x) >= 0.75
    // Solving: attended + x >= 0.75 * (total + x)
    // x >= (0.75 * total - attended) / 0.25
    final needed = ((0.75 * totalClasses - attendedClasses) / 0.25).ceil();
    return needed > 0 ? needed : 0;
  }

  /// How many classes can be skipped while staying at 75%
  int get classesCanSkip {
    if (percentage < 75) return 0;
    // Formula: attended / (total + x) >= 0.75
    // Solving: attended >= 0.75 * (total + x)
    // x <= (attended / 0.75) - total
    final canSkip = ((attendedClasses / 0.75) - totalClasses).floor();
    return canSkip > 0 ? canSkip : 0;
  }

  factory SubjectAttendance.fromJson(Map<String, dynamic> json) {
    return SubjectAttendance(
      subjectCode: json['subject_code'] ?? '',
      subjectName: json['subject_name'] ?? '',
      totalClasses: json['total_classes'] ?? 0,
      attendedClasses: json['attended_classes'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
      type: json['type'] ?? 'Theory',
      facultyName: json['faculty_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'subject_code': subjectCode,
      'subject_name': subjectName,
      'total_classes': totalClasses,
      'attended_classes': attendedClasses,
      'percentage': percentage,
      'type': type,
      'faculty_name': facultyName,
    };
  }

  // Mock data
  static List<SubjectAttendance> mockList() {
    return [
      SubjectAttendance(
        subjectCode: 'CS501',
        subjectName: 'Software Engineering',
        totalClasses: 45,
        attendedClasses: 40,
        percentage: 88.9,
      ),
      SubjectAttendance(
        subjectCode: 'CS502',
        subjectName: 'Database Management Systems',
        totalClasses: 42,
        attendedClasses: 38,
        percentage: 90.5,
      ),
      SubjectAttendance(
        subjectCode: 'CS503',
        subjectName: 'Computer Networks',
        totalClasses: 40,
        attendedClasses: 32,
        percentage: 80.0,
      ),
      SubjectAttendance(
        subjectCode: 'CS504',
        subjectName: 'Operating Systems',
        totalClasses: 38,
        attendedClasses: 35,
        percentage: 92.1,
      ),
      SubjectAttendance(
        subjectCode: 'CS505',
        subjectName: 'Artificial Intelligence',
        totalClasses: 36,
        attendedClasses: 25,
        percentage: 69.4,
      ),
      SubjectAttendance(
        subjectCode: 'CS506',
        subjectName: 'Machine Learning',
        totalClasses: 30,
        attendedClasses: 28,
        percentage: 93.3,
      ),
    ];
  }
}
