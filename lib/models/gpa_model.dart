class GpaCourse {
  String id;
  String name;
  double credits;
  double marks;
  double totalMarks;
  
  GpaCourse({
    required this.id,
    this.name = '',
    this.credits = 3.0,
    this.marks = 0.0,
    this.totalMarks = 100.0,
  });

  // Calculate percentage for grade determination
  double get percentage => totalMarks > 0 ? (marks / totalMarks) * 100 : 0;

  // Calculate grade point based on CVM University UG Policy
  // using percentage logic
  int get gradePoint {
    final p = percentage;
    if (p >= 85) return 10;
    if (p >= 75) return 9;
    if (p >= 65) return 8;
    if (p >= 55) return 7;
    if (p >= 45) return 6;
    if (p >= 40) return 5;
    if (p >= 35) return 4;
    return 0; // Fail
  }

  String get grade {
    final p = percentage;
    if (p >= 85) return 'AA';
    if (p >= 75) return 'AB';
    if (p >= 65) return 'BB';
    if (p >= 55) return 'BC';
    if (p >= 45) return 'CC';
    if (p >= 40) return 'CD';
    if (p >= 35) return 'DD';
    return 'FF';
  }
}
