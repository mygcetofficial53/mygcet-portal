import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../services/timetable_service.dart';
import '../../services/auth_service.dart';
import '../../models/timetable_model.dart';
import '../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'timetable_setup_screen.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({Key? key}) : super(key: key);

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TimetableService _service = TimetableService();
  Timetable? _timetable;
  bool _isLoading = true;
  int _selectedDayIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  DateTime? _lastCheckedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadData();
    _updateSelectedDay();
    _animationController.forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, check if date has changed
    if (state == AppLifecycleState.resumed) {
      _checkDateChange();
    }
  }

  void _checkDateChange() {
    final now = DateTime.now();
    // Check if date is different from last check
    if (_lastCheckedDate == null || 
        _lastCheckedDate!.day != now.day || 
        _lastCheckedDate!.month != now.month || 
        _lastCheckedDate!.year != now.year) {
      _updateSelectedDay();
    }
  }

  void _updateSelectedDay() {
    final now = DateTime.now();
    _lastCheckedDate = now;
    int weekday = now.weekday;
    
    // Only update if it's a weekday (Mon-Sat = 1-6)
    if (weekday <= 6) {
      setState(() {
        _selectedDayIndex = weekday - 1;
      });
    } else {
      // Sunday - default to Monday
      setState(() {
        _selectedDayIndex = 0;
      });
    }
  }

  Future<void> _loadData() async {
    Timetable? saved = await _service.loadTimetable();
    setState(() {
      _timetable = saved;
      _isLoading = false;
    });
  }

  void _selectDay(int index) {
    if (_selectedDayIndex != index) {
      _animationController.reverse().then((_) {
        setState(() => _selectedDayIndex = index);
        _animationController.forward();
      });
    }
  }

  // Get dates for current week
  List<DateTime> _getWeekDates() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return List.generate(6, (i) => monday.add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(child: _buildDaySelector()),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: _buildTimeSlotList(),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      floatingActionButton: _buildFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.primaryGradient,
        ),
        child: FlexibleSpaceBar(
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
          title: const Text(
            'My Timetable',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          background: Stack(
            children: [
              Positioned(
                right: -50,
                top: -30,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                right: 40,
                top: 60,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
      ),
      actions: [
        IconButton(
          tooltip: 'Manage Subjects & Backup',
          onPressed: () async {
            await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TimetableSetupScreen()));
            _loadData();
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.settings_outlined, color: Colors.white, size: 20),
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDaySelector() {
    final weekDates = _getWeekDates();
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: List.generate(6, (index) {
          final isSelected = index == _selectedDayIndex;
          final date = weekDates[index];
          final isToday = DateUtils.isSameDay(date, DateTime.now());

          return Expanded(
            child: GestureDetector(
              onTap: () => _selectDay(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: isSelected ? AppTheme.primaryGradient : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      dayNames[index],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : isToday
                                ? AppTheme.primaryBlue
                                : AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withOpacity(0.2)
                            : isToday
                                ? AppTheme.primaryBlue.withOpacity(0.1)
                                : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : isToday
                                    ? AppTheme.primaryBlue
                                    : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTimeSlotList() {
    final selectedDay = WeekDay.values[_selectedDayIndex];
    List<TimeSlot> slots = _timetable?.weekSchedule[selectedDay.name] ?? [];
    // Sorting is handled by TimetableService
    // slots.sort((a, b) => a.startTime.compareTo(b.startTime)); // REMOVED: Caused String comparison bug (9 > 1)

    if (slots.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: _buildEmptyState(),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final slot = slots[index];
          return FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Slidable(
                key: Key("${slot.subject}_${slot.startTime}_$index"),
                endActionPane: ActionPane(
                  motion: const ScrollMotion(),
                  children: [
                    SlidableAction(
                      onPressed: (context) async {
                         // Confirm delete
                         final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Class?'),
                              content: const Text('Are you sure you want to remove this class from the schedule?'),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                         );
                         
                         if (confirm == true) {
                            await _service.removeSlot(selectedDay, slot);
                            _loadData();
                         }
                      },
                      backgroundColor: AppTheme.dangerRed,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: () => _showAddClassSheet(context, editSlot: slot),
                  child: Container(
                    child: _buildTimeSlotCard(slot),
                  ),
                ),
              ),
            ),
          );
        },
        childCount: slots.length,
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.calendar_today_outlined,
                size: 64,
                color: AppTheme.primaryBlue.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Classes Today',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add\nyour first class for ${WeekDay.values[_selectedDayIndex].name}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => _showAddClassSheet(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Class'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: BorderSide(color: AppTheme.primaryBlue),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSlotCard(TimeSlot slot) {
    final bool isLab = slot.isLab;

    // Colors matching original
    final Color cardBg = isLab ? const Color(0xFFFFF8E1) : const Color(0xFFE8F4FD);
    final Color accentColor = isLab ? const Color(0xFFFF8A65) : const Color(0xFF42A5F5);
    final Color timeBg = isLab ? const Color(0xFFFFE0B2) : const Color(0xFFBBDEFB);
    final Color timeText = isLab ? const Color(0xFFE65100) : const Color(0xFF1565C0);
    final String typeLabel = isLab ? 'Lab' : 'Lecture';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Gradient accent bar
              Container(
                width: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isLab
                        ? [const Color(0xFFFF8A65), const Color(0xFFE65100)]
                        : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                  ),
                ),
              ),

              // Time column
              Container(
                width: 80,
                color: timeBg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slot.startTime,
                      style: TextStyle(
                        color: timeText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Icon(
                        Icons.arrow_downward,
                        size: 14,
                        color: timeText.withOpacity(0.5),
                      ),
                    ),
                    Text(
                      slot.endTime,
                      style: TextStyle(
                        color: timeText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              // Details section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Type pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLab
                                ? [const Color(0xFFFF8A65), const Color(0xFFE65100)]
                                : [const Color(0xFF42A5F5), const Color(0xFF1565C0)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          typeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Subject name
                      Text(
                        slot.subject.isNotEmpty ? slot.subject : "No Subject",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1A1A2E),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),

                      // Faculty & Room row
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          if (slot.faculty.isNotEmpty)
                            _buildInfoChip(Icons.person_outline, slot.faculty),
                          if (slot.room.isNotEmpty)
                            _buildInfoChip(Icons.location_on_outlined, slot.room),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Swipe hint
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Icon(
                    Icons.chevron_left,
                    color: Colors.grey.withOpacity(0.3),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFAB() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddClassSheet(context),
        backgroundColor: AppTheme.primaryBlue,
        elevation: 6,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Add Class',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  void _showAddClassSheet(BuildContext context, {TimeSlot? editSlot}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddClassSheet(
        initialDay: WeekDay.values[_selectedDayIndex].name,
        existingSlot: editSlot,
        onAdd: (dayName, slot) async {
          final day = WeekDay.values.firstWhere((d) => d.name == dayName);
          if (editSlot != null) {
            // Remove old slot first
            await _service.removeSlot(day, editSlot);
          }
          await _service.addSlot(day, slot);
          _loadData();
        },
        onDelete: editSlot != null ? () async {
          final day = WeekDay.values[_selectedDayIndex];
          await _service.removeSlot(day, editSlot);
          _loadData();
        } : null,
      ),
    );
  }
}

class _AddClassSheet extends StatefulWidget {
  final String initialDay;
  final TimeSlot? existingSlot;
  final Function(String, TimeSlot) onAdd;
  final VoidCallback? onDelete;

  const _AddClassSheet({
    required this.initialDay, 
    this.existingSlot,
    required this.onAdd,
    this.onDelete,
  });

  @override
  State<_AddClassSheet> createState() => _AddClassSheetState();
}

class _AddClassSheetState extends State<_AddClassSheet> {
  final TimetableService _service = TimetableService();
  late String _selectedDay;
  final _codeController = TextEditingController();
  final _roomController = TextEditingController();

  Subject? _selectedSubject;
  Faculty? _selectedFaculty;
  List<Subject> _subjects = [];
  List<Faculty> _faculties = [];

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLab = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.initialDay;
    
    // Initialize with existing slot data if editing
    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      // Parse times
      try {
        final startDt = DateFormat("h:mm a").parse(slot.startTime);
        _startTime = TimeOfDay(hour: startDt.hour, minute: startDt.minute);
        final endDt = DateFormat("h:mm a").parse(slot.endTime);
        _endTime = TimeOfDay(hour: endDt.hour, minute: endDt.minute);
      } catch (e) {
        // Fallback or ignore
      }
      
      _isLab = slot.isLab;
      _roomController.text = slot.room;
      
      // Wait for metadata to load to set subject/faculty
    }
    
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    // First, sync subjects from registered courses (GMS)
    final authService = Provider.of<AuthService>(context, listen: false);
    final registeredCourses = authService.currentUser?.registeredCourses ?? [];
    if (registeredCourses.isNotEmpty) {
      await _service.syncSubjectsFromRegisteredCourses(registeredCourses);
    }
    
    final s = await _service.loadSubjects();
    final f = await _service.loadFaculties();
    
    if (mounted) {
      setState(() {
        _subjects = s;
        _faculties = f;
        _isLoading = false;
        
        // Match subject and faculty if editing
        if (widget.existingSlot != null) {
          final slot = widget.existingSlot!;
          try {
             _selectedSubject = _subjects.firstWhere((sub) => sub.name == slot.subject);
             _codeController.text = _selectedSubject?.code ?? '';
          } catch (_) {}
          
          try {
             _selectedFaculty = _faculties.firstWhere((fac) => fac.shortName == slot.faculty);
          } catch (_) {}
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.existingSlot != null ? "Edit Class" : "Add New Class",
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Fill in the details below",
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (widget.existingSlot != null)
                         IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Class?'),
                                content: const Text('Are you sure you want to remove this class?'),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                      widget.onDelete?.call();
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          tooltip: "Delete Class",
                        )
                      else if (_subjects.isEmpty || _faculties.isEmpty)
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TimetableSetupScreen()),
                            );
                          },
                          icon: const Icon(Icons.settings, size: 18),
                          label: const Text("Setup"),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                          ),
                        )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Subject Dropdown
                  DropdownButtonFormField<Subject>(
                    value: _selectedSubject,
                    items: _subjects
                        .map((s) => DropdownMenuItem(
                              value: s,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedSubject = val;
                        if (val != null) _codeController.text = val.code;
                      });
                    },
                    decoration: _inputDecoration("Subject Name *", Icons.book_outlined),
                    hint: const Text("Select Subject"),
                    isExpanded: true,
                  ),
                  const SizedBox(height: 16),

                  // Subject Code
                  TextField(
                    controller: _codeController,
                    decoration: _inputDecoration("Subject Code", Icons.code),
                  ),
                  const SizedBox(height: 16),

                  // Faculty & Room Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<Faculty>(
                          value: _selectedFaculty,
                          items: _faculties
                              .map((f) => DropdownMenuItem(
                                    value: f,
                                    child: Text(f.name, overflow: TextOverflow.ellipsis),
                                  ))
                              .toList(),
                          onChanged: (val) => setState(() => _selectedFaculty = val),
                          decoration: _inputDecoration("Faculty", Icons.person_outline),
                          hint: const Text("Select"),
                          isExpanded: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _roomController,
                          decoration: _inputDecoration("Room", Icons.location_on_outlined),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Day Selection
                  Text(
                    "Day",
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: WeekDay.values.map((day) {
                        bool isSelected = day.name == _selectedDay;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(day.name.substring(0, 3)),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryBlue,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (sel) => setState(() => _selectedDay = day.name),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Time Selection
                  Row(
                    children: [
                      Expanded(child: _buildTimePicker("Start Time", _startTime, (t) => setState(() => _startTime = t))),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTimePicker("End Time", _endTime, (t) => setState(() => _endTime = t))),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Lab toggle
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SwitchListTile(
                      title: const Text(
                        "Lab Session",
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Text(
                        "Toggle if this is a lab class",
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                      ),
                      value: _isLab,
                      onChanged: (v) => setState(() => _isLab = v),
                      activeColor: AppTheme.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Add Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_selectedSubject != null) {
                          final slot = TimeSlot(
                            subject: _selectedSubject!.name,
                            subjectCode: _codeController.text,
                            startTime: _formatTime(_startTime),
                            endTime: _formatTime(_endTime),
                            faculty: _selectedFaculty?.shortName ?? _selectedFaculty?.name ?? '',
                            room: _roomController.text,
                            isLab: _isLab,
                          );
                          widget.onAdd(_selectedDay, slot);
                          Navigator.pop(context);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Please select a subject")),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: const Text(
                        "Add Class",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20, color: AppTheme.textSecondary),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.primaryBlue, width: 1.5)),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay time, Function(TimeOfDay) onPick) {
    return GestureDetector(
      onTap: () async {
        final t = await showTimePicker(context: context, initialTime: time);
        if (t != null) onPick(t);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.access_time, size: 18, color: AppTheme.primaryBlue),
                const SizedBox(width: 8),
                Text(
                  _formatTime(time),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
    return DateFormat.jm().format(dt);
  }
}
