import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/event_model.dart';
import '../../services/event_service.dart';
import '../../services/auth_service.dart';
import 'digital_ticket_screen.dart';

class EventRegistrationScreen extends StatefulWidget {
  final Event event;

  const EventRegistrationScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventRegistrationScreen> createState() => _EventRegistrationScreenState();
}

class _EventRegistrationScreenState extends State<EventRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> _responses = {};
  
  // Team Controllers
  final TextEditingController _teamNameController = TextEditingController();
  final List<TextEditingController> _teamMemberControllers = [];
  
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.event.isTeamEvent) {
      // Initialize team member controllers based on min size (minus 1 for the leader/user)
      for (int i = 0; i < widget.event.minTeamSize - 1; i++) {
        _teamMemberControllers.add(TextEditingController());
      }
    }
  }
  
  void _addTeamMember() {
    if (_teamMemberControllers.length < widget.event.maxTeamSize - 1) {
      setState(() {
        _teamMemberControllers.add(TextEditingController());
      });
    }
  }

  void _removeTeamMember(int index) {
      setState(() {
        _teamMemberControllers.removeAt(index);
      });
  }

  Future<void> _submitRegistration() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    
    // Save form state to _responses
    _formKey.currentState!.save();

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final eventService = Provider.of<EventService>(context, listen: false);
      final studentId = authService.currentUser?.enrollment ?? 'guest';
      final studentName = authService.currentUser?.name ?? 'Guest User';

      // Collect team members
      List<String>? teamMembers;
      if (widget.event.isTeamEvent) {
        teamMembers = _teamMemberControllers.map((c) => c.text.trim()).toList();
        // Add current user to list (implicit)
        // teamMembers.add(studentId); 
      }

      final success = await eventService.registerForEvent(
        eventId: widget.event.id,
        studentId: studentId,
        studentName: studentName,
        responses: _responses,
        teamName: widget.event.isTeamEvent ? _teamNameController.text.trim() : null,
        teamMembers: teamMembers,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Successful!')));
          // Navigate to Ticket Screen
          // We need the registration object to show ticket. 
          // For now, pop or go to ticket details.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => DigitalTicketScreen(event: widget.event)),
          );
        }
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registration Failed. Event might be full.')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if fully booked
    final isFull = widget.event.isFull;
    final canJoinWaitlist = isFull && widget.event.allowWaitlist && !widget.event.isWaitlistFull;
    final cannotRegister = isFull && !canJoinWaitlist;

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        title: Text(widget.event.title),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
             // Event Summary Card
             Container(
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(16),
                 border: Border.all(color: Colors.white.withOpacity(0.1)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(children: [
                     Icon(Icons.calendar_today, color: Colors.blue[400], size: 16),
                     const SizedBox(width: 8),
                     Text(DateFormat('MMM dd, yyyy • ').format(widget.event.eventDate) + widget.event.startTime, style: const TextStyle(color: Colors.white70)),
                   ]),
                   const SizedBox(height: 8),
                   Row(children: [
                     Icon(Icons.location_on, color: Colors.red[400], size: 16),
                     const SizedBox(width: 8),
                     Text(widget.event.venue, style: const TextStyle(color: Colors.white70)),
                   ]),
                   if (widget.event.xpPoints > 0) ...[
                     const SizedBox(height: 12),
                     Container(
                       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                       decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                       child: Text('🎁 Earn ${widget.event.xpPoints} XP', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                     )
                   ]
                 ],
               ),
             ),
             
             const SizedBox(height: 24),
             if (cannotRegister)
                const Center(child: Text('Event is Full', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)))
             else ...[
               _buildSectionHeader('Registration Details'),
               
               // Dynamic Fields
               ...widget.event.formFields.map((field) => _buildDynamicField(field)).toList(),
               
               // Team Section
               if (widget.event.isTeamEvent) ...[
                 const SizedBox(height: 24),
                 _buildSectionHeader('Team Info'),
                 _buildTextField(
                   _teamNameController, 
                   'Team Name', 
                   Icons.group, 
                   validator: (v) => v!.isEmpty ? 'Team Name Required' : null
                 ),
                 const SizedBox(height: 12),
                 const Text('Team Members (Enrollment Nos)', style: TextStyle(color: Colors.white70)),
                 const SizedBox(height: 8),
                 ..._teamMemberControllers.asMap().entries.map((entry) {
                   return Padding(
                     padding: const EdgeInsets.only(bottom: 8.0),
                     child: _buildTeamMemberField(entry.key, entry.value),
                   );
                 }).toList(),
                 
                 if (_teamMemberControllers.length < widget.event.maxTeamSize - 1)
                   TextButton.icon(
                     onPressed: _addTeamMember,
                     icon: const Icon(Icons.add),
                     label: const Text('Add Team Member'),
                     style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
                   ),
               ],
             ],

             const SizedBox(height: 32),
             if (!cannotRegister)
             SizedBox(
               height: 56,
               child: ElevatedButton(
                 onPressed: _isSubmitting ? null : _submitRegistration,
                 style: ElevatedButton.styleFrom(
                   backgroundColor: canJoinWaitlist ? Colors.orange : const Color(0xFF8B5CF6),
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                 ),
                 child: _isSubmitting 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                     canJoinWaitlist ? 'JOIN WAITLIST' : 'CONFIRM REGISTRATION',
                     style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
               ),
             ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDynamicField(EventField field) {
    switch (field.type) {
      case EventFieldType.text:
      case EventFieldType.number:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TextFormField(
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(field.name, Icons.edit),
            keyboardType: field.type == EventFieldType.number ? TextInputType.number : TextInputType.text,
            validator: field.isRequired ? (v) => v!.isEmpty ? 'Required' : null : null,
            onSaved: (v) => _responses[field.id] = v,
          ),
        );
      
      case EventFieldType.dropdown:
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: DropdownButtonFormField<String>(
            items: field.options?.map((o) => DropdownMenuItem(value: o, child: Text(o))).toList() ?? [],
            onChanged: (v) => _responses[field.id] = v,
            dropdownColor: const Color(0xFF16213e),
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(field.name, Icons.list),
            validator: field.isRequired ? (v) => v == null ? 'Required' : null : null,
          ),
        );
        
      case EventFieldType.checkbox:
         // Using a switch tile for boolean
         return Padding(
           padding: const EdgeInsets.only(bottom: 16),
           child: FormField<bool>(
             initialValue: false,
             validator: field.isRequired ? (v) => v == true ? null : 'Required' : null,
             onSaved: (v) => _responses[field.id] = v,
             builder: (state) {
               return SwitchListTile(
                 title: Text(field.name, style: const TextStyle(color: Colors.white)),
                 value: state.value ?? false,
                 onChanged: (val) => state.didChange(val),
                 activeColor: const Color(0xFF8B5CF6),
                 subtitle: state.hasError ? Text(state.errorText!, style: const TextStyle(color: Colors.red, fontSize: 12)) : null,
               );
             },
           ),
         );
         
      default:
        return Container();
    }
  }

  Widget _buildTeamMemberField(int index, TextEditingController controller) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: controller,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration('Member ${index + 2} Enrollment No', Icons.person),
            validator: (v) => v!.isEmpty ? 'Required' : null,
          ),
        ),
        IconButton(
          onPressed: () => _removeTeamMember(index),
          icon: const Icon(Icons.remove_circle, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF8B5CF6))),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}
