class Student {
  final String id;
  final String name;
  final String rollNumber;
  final String enrollment;
  final String email;
  final String phone;
  final String branch;
  final String semester;
  final String section;
  final String batch;
  final String fatherName;
  final String motherName;
  final String mentorName;
  final String mentorEmail;
  final String address;
  final String? photoUrl;
  final double overallAttendance;
  final List<RegisteredCourse> registeredCourses;

  Student({
    required this.id,
    required this.name,
    required this.rollNumber,
    this.enrollment = '',
    required this.email,
    this.phone = '',
    required this.branch,
    required this.semester,
    required this.section,
    this.batch = '',
    this.fatherName = '',
    this.motherName = '',
    this.mentorName = '',
    this.mentorEmail = '',
    this.address = '',
    this.photoUrl,
    this.overallAttendance = 0.0,
    this.registeredCourses = const [],
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    List<RegisteredCourse> courses = [];
    if (json['registered_courses'] != null) {
      courses = (json['registered_courses'] as List)
          .map((c) => RegisteredCourse.fromJson(c))
          .toList();
    }

    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Student',
      rollNumber: json['roll_number'] ?? json['enrollment'] ?? '',
      enrollment: json['enrollment'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      branch: json['branch'] ?? '',
      semester: json['semester'] ?? '',
      section: json['section'] ?? '',
      batch: json['batch'] ?? '',
      fatherName: json['father_name'] ?? '',
      motherName: json['mother_name'] ?? '',
      mentorName: json['mentor_name'] ?? '',
      mentorEmail: json['mentor_email'] ?? '',
      address: json['address'] ?? '',
      photoUrl: json['photo_url'],
      overallAttendance: (json['overall_attendance'] ?? 0).toDouble(),
      registeredCourses: courses,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'roll_number': rollNumber,
      'enrollment': enrollment,
      'email': email,
      'phone': phone,
      'branch': branch,
      'semester': semester,
      'section': section,
      'batch': batch,
      'father_name': fatherName,
      'mother_name': motherName,
      'mentor_name': mentorName,
      'mentor_email': mentorEmail,
      'address': address,
      'photo_url': photoUrl,
      'overall_attendance': overallAttendance,
      'registered_courses': registeredCourses.map((c) => c.toJson()).toList(),
    };
  }

  /// Create a copy of this Student with updated fields
  Student copyWith({
    String? id,
    String? name,
    String? rollNumber,
    String? enrollment,
    String? email,
    String? phone,
    String? branch,
    String? semester,
    String? section,
    String? batch,
    String? fatherName,
    String? motherName,
    String? mentorName,
    String? mentorEmail,
    String? address,
    String? photoUrl,
    double? overallAttendance,
    List<RegisteredCourse>? registeredCourses,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      rollNumber: rollNumber ?? this.rollNumber,
      enrollment: enrollment ?? this.enrollment,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      branch: branch ?? this.branch,
      semester: semester ?? this.semester,
      section: section ?? this.section,
      batch: batch ?? this.batch,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      mentorName: mentorName ?? this.mentorName,
      mentorEmail: mentorEmail ?? this.mentorEmail,
      address: address ?? this.address,
      photoUrl: photoUrl ?? this.photoUrl,
      overallAttendance: overallAttendance ?? this.overallAttendance,
      registeredCourses: registeredCourses ?? this.registeredCourses,
    );
  }

  // Mock data for testing
  static Student mock() {
    return Student(
      id: '1',
      name: 'John Doe',
      rollNumber: '21A91A0501',
      enrollment: '12502080503001',
      email: 'john.doe@gcet.edu.in',
      phone: '9876543210',
      branch: 'Computer Science',
      semester: '5th',
      section: 'A',
      batch: '2021-2025',
      fatherName: 'Mr. Doe',
      motherName: 'Mrs. Doe',
      overallAttendance: 85.5,
      registeredCourses: [
        RegisteredCourse(code: 'CS501', name: 'Machine Learning', type: 'Theory'),
        RegisteredCourse(code: 'CS502', name: 'Computer Networks', type: 'Theory'),
      ],
    );
  }

  // Demo data with realistic GCET student info
  static Student demo() {
    return Student(
      id: 'DEMO001',
      name: 'Rahul Kumar Sharma',
      rollNumber: '22A91A05G1',
      enrollment: '12502220503001',
      email: 'rahul.sharma@gcet.edu.in',
      phone: '9876543210',
      branch: 'Computer Science and Engineering',
      semester: '5th Semester',
      section: 'G',
      batch: '2022-2026',
      fatherName: 'Mr. Ramesh Sharma',
      motherName: 'Mrs. Sunita Sharma',
      address: 'Hyderabad, Telangana',
      overallAttendance: 87.5,
      registeredCourses: [
        RegisteredCourse(code: 'CS501', name: 'Software Engineering', type: 'Theory'),
        RegisteredCourse(code: 'CS502', name: 'Database Management Systems', type: 'Theory'),
        RegisteredCourse(code: 'CS503', name: 'Computer Networks', type: 'Theory'),
        RegisteredCourse(code: 'CS504', name: 'Operating Systems', type: 'Theory'),
        RegisteredCourse(code: 'CS505', name: 'Artificial Intelligence', type: 'Theory'),
        RegisteredCourse(code: 'CS506', name: 'Machine Learning', type: 'Theory'),
        RegisteredCourse(code: 'CS507', name: 'Web Technologies Lab', type: 'Lab'),
        RegisteredCourse(code: 'CS508', name: 'DBMS Lab', type: 'Lab'),
      ],
    );
  }
}

class RegisteredCourse {
  final String code;
  final String name;
  final String type;

  RegisteredCourse({
    required this.code,
    required this.name,
    this.type = '',
  });

  factory RegisteredCourse.fromJson(Map<String, dynamic> json) {
    return RegisteredCourse(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'name': name,
      'type': type,
    };
  }
}
