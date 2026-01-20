import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';

class AdminCreateEventScreen extends StatefulWidget {
  final Event? event;

  const AdminCreateEventScreen({Key? key, this.event}) : super(key: key);

  @override
  State<AdminCreateEventScreen> createState() => _AdminCreateEventScreenState();
}

class _AdminCreateEventScreenState extends State<AdminCreateEventScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Info
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _venueController;
  late TextEditingController _maxParticipantsController;
  late String _category;
  late DateTime _eventDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late TextEditingController _imageUrlController;

  // Advanced Settings
  bool _isTeamEvent = false;
  late TextEditingController _minTeamSizeController;
  late TextEditingController _maxTeamSizeController;
  
  bool _allowWaitlist = false;
  late TextEditingController _waitlistCapacityController;

  bool _requiresCertificate = false;
  late TextEditingController _xpPointsController;
  
  late TextEditingController _scannerPinController;

  // Dynamic Fields
  List<EventField> _formFields = [];

  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final e = widget.event;
    
    _titleController = TextEditingController(text: e?.title ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _venueController = TextEditingController(text: e?.venue ?? '');
    _maxParticipantsController = TextEditingController(text: e?.maxParticipants.toString() ?? '100');
    _category = e?.category ?? EventCategories.all.first;
    _eventDate = e?.eventDate ?? DateTime.now().add(const Duration(days: 7));
    _startTime = _parseTimeString(e?.startTime) ?? const TimeOfDay(hour: 9, minute: 0);
    _endTime = _parseTimeString(e?.endTime) ?? const TimeOfDay(hour: 17, minute: 0);
    _imageUrlController = TextEditingController(text: e?.imageUrl ?? '');

    _isTeamEvent = e?.isTeamEvent ?? false;
    _minTeamSizeController = TextEditingController(text: e?.minTeamSize.toString() ?? '2');
    _maxTeamSizeController = TextEditingController(text: e?.maxTeamSize.toString() ?? '4');

    _allowWaitlist = e?.allowWaitlist ?? false;
    _waitlistCapacityController = TextEditingController(text: e?.waitlistCapacity.toString() ?? '20');

    _requiresCertificate = e?.requiresCertificate ?? false;
    _xpPointsController = TextEditingController(text: e?.xpPoints.toString() ?? '50');
    _scannerPinController = TextEditingController(text: e?.scannerPin ?? '');

    if (e != null) {
      _formFields = List.from(e.formFields);
    }
  }

  TimeOfDay? _parseTimeString(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1].replaceAll(RegExp(r'[^\d]'), ''));
        if (timeStr.toLowerCase().contains('pm') && hour < 12) hour += 12;
        if (timeStr.toLowerCase().contains('am') && hour == 12) hour = 0;
        return TimeOfDay(hour: hour, minute: minute);
      }
    } catch (_) {}
    return null;
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat.jm().format(dt);
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final eventService = Provider.of<EventService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Determine status and creator
    final isAdmin = authService.currentUser?.id == 'admin';
    // If updating an existing event, preserve its status unless specifically changed (logic could be complex, for now keep logic simple)
    // If admin edits, it stays approved/pending (or auto-approves?). 
    // Let's say: New events by non-admin are PENDING. Admin edits make it APPROVED.
    
    final status = isAdmin ? 'approved' : 'pending'; 
    final createdBy = isAdmin ? 'admin' : authService.currentUser?.enrollment;

    final event = Event(
      id: widget.event?.id ?? 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      category: _category,
      eventDate: _eventDate,
      startTime: _formatTimeOfDay(_startTime),
      endTime: _formatTimeOfDay(_endTime),
      venue: _venueController.text.trim(),
      maxParticipants: int.tryParse(_maxParticipantsController.text) ?? 100,
      imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
      isActive: widget.event?.isActive ?? true,
      status: widget.event != null ? widget.event!.status : status, // Preserve status on edit, or use new status defaults
      createdBy: widget.event?.createdBy ?? createdBy,
      createdAt: widget.event?.createdAt,
      
      // Advanced
      isTeamEvent: _isTeamEvent,
      minTeamSize: int.tryParse(_minTeamSizeController.text) ?? 1,
      maxTeamSize: int.tryParse(_maxTeamSizeController.text) ?? 1,
      allowWaitlist: _allowWaitlist,
      waitlistCapacity: int.tryParse(_waitlistCapacityController.text) ?? 0,
      requiresCertificate: _requiresCertificate,
      xpPoints: int.tryParse(_xpPointsController.text) ?? 0,
      scannerPin: _scannerPinController.text.trim().isEmpty ? null : _scannerPinController.text.trim(),
      formFields: _formFields,
      registrations: widget.event?.registrations ?? [],
    );

    if (widget.event == null) {
      await eventService.createEvent(event);
    } else {
      await eventService.updateEvent(event);
    }

    if (mounted) Navigator.pop(context);
  }

  void _addFormField() {
    setState(() {
      _formFields.add(EventField(
        id: _uuid.v4(),
        name: 'New Question',
        type: EventFieldType.text,
        isRequired: true,
      ));
    });
  }

  void _removeFormField(int index) {
    setState(() {
      _formFields.removeAt(index);
    });
  }

  void _updateFormField(int index, EventField field) {
    setState(() {
      _formFields[index] = field;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(widget.event == null ? 'Create Event' : 'Edit Event'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('Basic Details'),
            _buildTextField(_titleController, 'Event Title', Icons.title, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            _buildTextField(_descriptionController, 'Description', Icons.description, maxLines: 3, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            
            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _category,
              items: EventCategories.all.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => _category = v!),
              dropdownColor: const Color(0xFF16213e),
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration('Category', Icons.category),
            ),
            const SizedBox(height: 12),

            // Date & Time
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _eventDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) setState(() => _eventDate = date);
                    },
                    child: AbsorbPointer(
                      child: _buildTextField(
                        TextEditingController(text: DateFormat('MMM dd, yyyy').format(_eventDate)),
                        'Date',
                        Icons.calendar_today,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _startTime);
                      if (time != null) setState(() => _startTime = time);
                    },
                    child: AbsorbPointer(
                      child: _buildTextField(
                        TextEditingController(text: _formatTimeOfDay(_startTime)),
                        'Start Time',
                        Icons.access_time,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final time = await showTimePicker(context: context, initialTime: _endTime);
                      if (time != null) setState(() => _endTime = time);
                    },
                    child: AbsorbPointer(
                      child: _buildTextField(
                        TextEditingController(text: _formatTimeOfDay(_endTime)),
                        'End Time',
                        Icons.access_time_filled,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildTextField(_venueController, 'Venue', Icons.location_on, validator: (v) => v!.isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            _buildTextField(_maxParticipantsController, 'Max Participants', Icons.people, keyboardType: TextInputType.number),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Registration Form Builder'),
            Text(
              'Customize the questions users answer when registering.',
              style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
            ),
            const SizedBox(height: 12),
            
            ..._formFields.asMap().entries.map((entry) {
              final index = entry.key;
              final field = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('Question ${index + 1}', style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold))),
                        IconButton(onPressed: () => _removeFormField(index), icon: const Icon(Icons.delete, color: Colors.red, size: 20)),
                      ],
                    ),
                    TextFormField(
                      initialValue: field.name,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'e.g. T-Shirt Size', hintStyle: TextStyle(color: Colors.white30)),
                      onChanged: (val) => _updateFormField(index, EventField(id: field.id, name: val, type: field.type, isRequired: field.isRequired, options: field.options)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<EventFieldType>(
                            value: field.type,
                            items: EventFieldType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last.toUpperCase()))).toList(),
                            onChanged: (val) => _updateFormField(index, EventField(id: field.id, name: field.name, type: val!, isRequired: field.isRequired, options: field.options)),
                            dropdownColor: const Color(0xFF16213e),
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Row(
                          children: [
                            Checkbox(
                              value: field.isRequired,
                              onChanged: (val) => _updateFormField(index, EventField(id: field.id, name: field.name, type: field.type, isRequired: val!, options: field.options)),
                              fillColor: MaterialStateProperty.all(const Color(0xFF8B5CF6)),
                            ),
                            const Text('Required', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                     if (field.type == EventFieldType.dropdown)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: TextFormField(
                          initialValue: field.options?.join(', '),
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(hintText: 'Options (comma separated)', hintStyle: TextStyle(color: Colors.white30)),
                          onChanged: (val) => _updateFormField(index, EventField(
                            id: field.id, 
                            name: field.name, 
                            type: field.type, 
                            isRequired: field.isRequired, 
                            options: val.split(',').map((e) => e.trim()).toList())
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
            
            OutlinedButton.icon(
              onPressed: _addFormField,
              icon: const Icon(Icons.add),
              label: const Text('Add Custom Question'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Advanced Settings'),
            
            // Team Switch
            SwitchListTile(
              title: const Text('Team Registration', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Users register as a group', style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _isTeamEvent,
              onChanged: (val) => setState(() => _isTeamEvent = val),
              activeColor: const Color(0xFF8B5CF6),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isTeamEvent)
              Row(
                children: [
                  Expanded(child: _buildTextField(_minTeamSizeController, 'Min Size', Icons.group_remove, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_maxTeamSizeController, 'Max Size', Icons.group_add, keyboardType: TextInputType.number)),
                ],
              ),

             // Waitlist Switch
            SwitchListTile(
              title: const Text('Allow Waitlist', style: TextStyle(color: Colors.white)),
              subtitle: const Text('When full, users can join waitlist', style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _allowWaitlist,
              onChanged: (val) => setState(() => _allowWaitlist = val),
              activeColor: const Color(0xFF8B5CF6),
              contentPadding: EdgeInsets.zero,
            ),
            if (_allowWaitlist)
              _buildTextField(_waitlistCapacityController, 'Waitlist Capacity', Icons.timer, keyboardType: TextInputType.number),

            // Certificate Switch
            SwitchListTile(
              title: const Text('Issue Certificates', style: TextStyle(color: Colors.white)),
              subtitle: const Text('Auto-generate PDFs for attendees', style: TextStyle(color: Colors.white54, fontSize: 12)),
              value: _requiresCertificate,
              onChanged: (val) => setState(() => _requiresCertificate = val),
              activeColor: const Color(0xFF8B5CF6),
              contentPadding: EdgeInsets.zero,
            ),
            
            // XP & Scanner
             const SizedBox(height: 12),
             Row(
                children: [
                  Expanded(child: _buildTextField(_xpPointsController, 'XP Points', Icons.star, keyboardType: TextInputType.number)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField(_scannerPinController, 'Volunteer PIN', Icons.lock)),
                ],
              ),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _saveEvent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  widget.event == null ? 'CREATE EVENT' : 'UPDATE EVENT',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(width: 4, height: 20, color: const Color(0xFF8B5CF6)),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      validator: validator,
      decoration: _inputDecoration(label, icon),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      prefixIcon: Icon(icon, color: Colors.white54, size: 20),
      filled: true,
      fillColor: Colors.white.withOpacity(0.08),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
