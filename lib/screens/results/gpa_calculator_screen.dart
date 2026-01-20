import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/gpa_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/apple_card.dart';
import '../../widgets/animated_gradient_background.dart';

class GpaCalculatorScreen extends StatefulWidget {
  const GpaCalculatorScreen({super.key});

  @override
  State<GpaCalculatorScreen> createState() => _GpaCalculatorScreenState();
}

class _GpaCalculatorScreenState extends State<GpaCalculatorScreen> {
  final List<GpaCourse> _courses = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize with data from profile if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSubjectsFromProfile();
    });
  }

  void _loadSubjectsFromProfile() {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;
    
    if (user != null && user.registeredCourses.isNotEmpty) {
      if (mounted) {
        setState(() {
          for (var course in user.registeredCourses) {
            _courses.add(GpaCourse(
              id: course.code, // Use code as ID for uniqueness
              name: course.name,
              credits: 3.0, // Default estimation, user can adjust
            ));
          }
        });
      }
    } else {
      // Add initial empty courses if no profile data
      if (mounted) {
        _addCourse();
        _addCourse();
        _addCourse();
      }
    }
  }

  void _addCourse() {
    setState(() {
      _courses.add(GpaCourse(
        id: DateTime.now().millisecondsSinceEpoch.toString() + _courses.length.toString(),
        name: 'Subject ${_courses.length + 1}',
      ));
    });
  }

  void _removeCourse(int index) {
    setState(() {
      _courses.removeAt(index);
    });
  }

  void _resetAll() {
    setState(() {
      _courses.clear();
      _addCourse();
      _addCourse();
      _addCourse();
    });
  }

  double get _calculatedSGPA {
    double totalCredits = 0;
    double weightedPoints = 0;

    for (var course in _courses) {
      // Only include courses that have been touched/modified meaningfuly? 
      // For now, include all. Default marks is 0, so it will drag down GPA if left empty.
      // Maybe we can filter out courses with 0 credits?
      
      if (course.credits > 0) {
        totalCredits += course.credits;
        weightedPoints += (course.credits * course.gradePoint);
      }
    }

    if (totalCredits == 0) return 0.0;
    return weightedPoints / totalCredits;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sgpa = _calculatedSGPA;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : AppTheme.backgroundLight,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('GPA Calculator'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: const ColorFilter.mode(Colors.transparent, BlendMode.src),
            child: Container(
              color: (isDark ? const Color(0xFF0D1117) : AppTheme.backgroundLight).withOpacity(0.8),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetAll,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Stack(
        children: [
          if (isDark) const Positioned.fill(child: AnimatedGradientBackground()),
          
          SafeArea(
            child: Column(
              children: [
                // Result Card
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppleCard(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          'Your SGPA',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sgpa.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: _getGpaColor(sgpa),
                          ),
                        ),
                        if (sgpa > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            _getMotivationalMessage(sgpa),
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),

                // Course List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _courses.length + 1, // +1 for Add button
                    itemBuilder: (context, index) {
                      if (index == _courses.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32, top: 8),
                          child: TextButton.icon(
                            onPressed: _addCourse,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add Subject'),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      return _buildCourseItem(index, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseItem(int index, bool isDark) {
    final course = _courses[index];
    
    return Dismissible(
      key: Key(course.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: Colors.red),
      ),
      onDismissed: (_) => _removeCourse(index),
      child: AppleCard(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: course.name,
                    decoration: InputDecoration(
                      hintText: 'Subject Name',
                      border: InputBorder.none,
                      hintStyle: TextStyle(
                        color: isDark ? Colors.white30 : Colors.grey.shade400,
                      ),
                    ),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    onChanged: (val) => course.name = val,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                  onPressed: () => _removeCourse(index),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREDITS',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<double>(
                            value: course.credits,
                            isExpanded: true,
                            dropdownColor: isDark ? const Color(0xFF1E242C) : Colors.white,
                            items: [0, 1, 2, 3, 4, 5, 6].map((e) => DropdownMenuItem(
                              value: e.toDouble(),
                              child: Text('${e.toInt()}'),
                            )).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => course.credits = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MARKS / TOTAL',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                initialValue: course.marks > 0 ? course.marks.toInt().toString() : '',
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '0',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    course.marks = double.tryParse(val) ?? 0;
                                  });
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '/',
                              style: TextStyle(
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: TextFormField(
                                initialValue: course.totalMarks.toInt().toString(),
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: '100',
                                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    course.totalMarks = double.tryParse(val) ?? 100;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'GRADE',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getGradeColor(course.gradePoint).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _getGradeColor(course.gradePoint).withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          course.grade,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _getGradeColor(course.gradePoint),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGpaColor(double gpa) {
    if (gpa >= 9.0) return Colors.greenAccent;
    if (gpa >= 8.0) return Colors.lightGreenAccent;
    if (gpa >= 7.0) return Colors.yellowAccent;
    if (gpa >= 6.0) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getGradeColor(int gradePoint) {
    if (gradePoint >= 9) return Colors.green;
    if (gradePoint >= 7) return Colors.amber;
    if (gradePoint >= 5) return Colors.orange;
    return Colors.red;
  }

  String _getMotivationalMessage(double gpa) {
    if (gpa >= 9.0) return "Outstanding! keep it up! 🚀";
    if (gpa >= 8.0) return "Excellent work! 🌟";
    if (gpa >= 7.0) return "Good job! 👍";
    if (gpa >= 6.0) return "Doing okay, push harder! 💪";
    return "Don't give up, you can do this! 🔥";
  }
}
