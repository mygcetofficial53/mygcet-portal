/// Result model for semester-wise academic results
class SemesterResult {
  final int semester;
  final double spi; // Semester Performance Index
  final double cpi; // Cumulative Performance Index
  final int totalCredits;
  final int earnedCredits;
  final List<SubjectResult> subjects;
  final String? status; // Pass/Fail/In Progress

  SemesterResult({
    required this.semester,
    required this.spi,
    required this.cpi,
    required this.totalCredits,
    required this.earnedCredits,
    required this.subjects,
    this.status,
  });

  factory SemesterResult.fromJson(Map<String, dynamic> json) {
    List<SubjectResult> subjectsList = [];
    if (json['subjects'] != null) {
      subjectsList = (json['subjects'] as List)
          .map((s) => SubjectResult.fromJson(s))
          .toList();
    }

    return SemesterResult(
      semester: json['semester'] ?? 0,
      spi: (json['spi'] ?? 0).toDouble(),
      cpi: (json['cpi'] ?? 0).toDouble(),
      totalCredits: json['total_credits'] ?? 0,
      earnedCredits: json['earned_credits'] ?? 0,
      subjects: subjectsList,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semester': semester,
      'spi': spi,
      'cpi': cpi,
      'total_credits': totalCredits,
      'earned_credits': earnedCredits,
      'subjects': subjects.map((s) => s.toJson()).toList(),
      'status': status,
    };
  }
}

class SubjectResult {
  final String code;
  final String name;
  final String grade;
  final double gradePoints;
  final int credits;
  final String type; // Theory/Lab/Project
  final String? status; // Pass/Fail/R (Remedial)

  SubjectResult({
    required this.code,
    required this.name,
    required this.grade,
    required this.gradePoints,
    required this.credits,
    this.type = 'Theory',
    this.status,
  });

  factory SubjectResult.fromJson(Map<String, dynamic> json) {
    return SubjectResult(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      grade: json['grade'] ?? '-',
      gradePoints: (json['grade_points'] ?? 0).toDouble(),
      credits: json['credits'] ?? 0,
      type: json['type'] ?? 'Theory',
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'grade': grade,
      'grade_points': gradePoints,
      'credits': credits,
      'type': type,
      'status': status,
    };
  }

  /// Get color based on grade
  static int getGradeColor(String grade) {
    switch (grade.toUpperCase()) {
      case 'O':
      case 'A+':
        return 0xFF34C759; // Green
      case 'A':
      case 'B+':
        return 0xFF5AC8FA; // Blue
      case 'B':
      case 'C+':
        return 0xFFFF9500; // Orange
      case 'C':
      case 'D':
        return 0xFFFF9500; // Orange
      case 'F':
      case 'R':
        return 0xFFFF3B30; // Red
      default:
        return 0xFF8E8E93; // Gray
    }
  }
}

// Demo data for results
class DemoResultsData {
  static List<SemesterResult> getResults() {
    return [
      SemesterResult(
        semester: 5,
        spi: 8.75,
        cpi: 8.42,
        totalCredits: 22,
        earnedCredits: 22,
        status: 'In Progress',
        subjects: [
          SubjectResult(code: 'CS501', name: 'Software Engineering', grade: 'A+', gradePoints: 9.0, credits: 3),
          SubjectResult(code: 'CS502', name: 'Database Management Systems', grade: 'A', gradePoints: 8.5, credits: 3),
          SubjectResult(code: 'CS503', name: 'Computer Networks', grade: 'A+', gradePoints: 9.0, credits: 3),
          SubjectResult(code: 'CS504', name: 'Operating Systems', grade: 'A', gradePoints: 8.5, credits: 3),
          SubjectResult(code: 'CS505', name: 'Artificial Intelligence', grade: 'B+', gradePoints: 8.0, credits: 3),
          SubjectResult(code: 'CS506', name: 'Machine Learning', grade: 'A+', gradePoints: 9.0, credits: 3),
          SubjectResult(code: 'CS507', name: 'Web Technologies Lab', grade: 'O', gradePoints: 10.0, credits: 2, type: 'Lab'),
          SubjectResult(code: 'CS508', name: 'DBMS Lab', grade: 'A+', gradePoints: 9.0, credits: 2, type: 'Lab'),
        ],
      ),
      SemesterResult(
        semester: 4,
        spi: 8.50,
        cpi: 8.35,
        totalCredits: 24,
        earnedCredits: 24,
        status: 'Pass',
        subjects: [
          SubjectResult(code: 'CS401', name: 'Data Structures', grade: 'A+', gradePoints: 9.0, credits: 4),
          SubjectResult(code: 'CS402', name: 'Design & Analysis of Algorithms', grade: 'A', gradePoints: 8.5, credits: 4),
          SubjectResult(code: 'CS403', name: 'Object Oriented Programming', grade: 'A', gradePoints: 8.5, credits: 3),
          SubjectResult(code: 'CS404', name: 'Computer Organization', grade: 'B+', gradePoints: 8.0, credits: 3),
          SubjectResult(code: 'CS405', name: 'Discrete Mathematics', grade: 'A', gradePoints: 8.5, credits: 3),
          SubjectResult(code: 'CS406', name: 'DS Lab', grade: 'O', gradePoints: 10.0, credits: 2, type: 'Lab'),
          SubjectResult(code: 'CS407', name: 'OOP Lab', grade: 'A+', gradePoints: 9.0, credits: 2, type: 'Lab'),
        ],
      ),
      SemesterResult(
        semester: 3,
        spi: 8.25,
        cpi: 8.20,
        totalCredits: 22,
        earnedCredits: 22,
        status: 'Pass',
        subjects: [
          SubjectResult(code: 'CS301', name: 'Digital Logic Design', grade: 'A', gradePoints: 8.5, credits: 4),
          SubjectResult(code: 'CS302', name: 'Mathematics III', grade: 'B+', gradePoints: 8.0, credits: 4),
          SubjectResult(code: 'CS303', name: 'Programming in C', grade: 'A+', gradePoints: 9.0, credits: 3),
          SubjectResult(code: 'CS304', name: 'Electronic Devices', grade: 'B+', gradePoints: 8.0, credits: 3),
          SubjectResult(code: 'CS305', name: 'Environmental Science', grade: 'A', gradePoints: 8.5, credits: 2),
          SubjectResult(code: 'CS306', name: 'DLD Lab', grade: 'A+', gradePoints: 9.0, credits: 2, type: 'Lab'),
          SubjectResult(code: 'CS307', name: 'C Programming Lab', grade: 'O', gradePoints: 10.0, credits: 2, type: 'Lab'),
        ],
      ),
    ];
  }
}

class MidSemResult {
  final String subjectCode;
  final String subjectName;
  final double marks;
  final double totalMarks;
  
  MidSemResult({
    required this.subjectCode,
    required this.subjectName,
    required this.marks,
    required this.totalMarks,
  });
}

class ExamPaperLink {
  final String title;
  final String url;
  
  ExamPaperLink({required this.title, required this.url});
}
