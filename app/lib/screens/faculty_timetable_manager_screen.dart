import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../widgets/vesit_widgets.dart';
import '../ams/globals.dart';
import '../widgets/vesit_toast.dart';

String _formatTimeString(String timeStr) {
  if (timeStr == 'N/A' || timeStr.isEmpty) return timeStr;
  try {
    final parts = timeStr.trim().split(':');
    int h = int.parse(parts[0]);
    final m = parts[1].split(' ')[0];
    final amPm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:$m $amPm';
  } catch (e) {
    return timeStr;
  }
}

class FacultyTimetableManagerScreen extends StatefulWidget {
  const FacultyTimetableManagerScreen({super.key});

  @override
  State<FacultyTimetableManagerScreen> createState() => _FacultyTimetableManagerScreenState();
}

class _FacultyTimetableManagerScreenState extends State<FacultyTimetableManagerScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  void _showAddSlotModal(String initialDay) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _AddSlotModal(initialDay: initialDay, days: _days);
      },
    ).then((newSlot) async {
      if (newSlot != null && newSlot is Map<String, dynamic>) {
        newSlot['facultyId'] = AmsGlobals.loggedInUser?.id;
        final error = await AmsGlobals.sessionService.createTimetableSlot(newSlot);
        if (error == null) {
          final updatedSlots = await AmsGlobals.sessionService.getTimetable(AmsGlobals.loggedInUser!.id);
          setState(() {
            AmsGlobals.timetableSlots.clear();
            AmsGlobals.timetableSlots.addAll(updatedSlots);
            _sortSlots();
          });
          if (mounted) {
            VesitToast.show(context: context, title: 'Timetable slot added successfully!', type: ToastType.info);
          }
        } else {
          if (mounted) {
            // Error contains the conflict message from backend
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(error, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ));
          }
        }
      }
    });
  }

  void _sortSlots() {
    AmsGlobals.timetableSlots.sort((a, b) {
      final tA = a['startTime'] as String? ?? '00:00';
      final tB = b['startTime'] as String? ?? '00:00';
      return tA.compareTo(tB);
    });
  }

  void _deleteSlot(Map<String, dynamic> slotToDelete) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: context.colors.vesitWhite.withValues(alpha: 0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 24),
                Icon(Icons.warning_amber_rounded, size: 48, color: context.colors.error),
                const SizedBox(height: 16),
                Text(
                  'Delete Timetable Slot?',
                  style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete this slot for ${slotToDelete['subject']}? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Cancel', style: context.textStyles.vesitLabelBold.copyWith(color: Colors.grey.shade700)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(ctx).pop();
                          
                          if (slotToDelete['id'] == null) return;
                          
                          final success = await AmsGlobals.sessionService.deleteTimetableSlot(slotToDelete['id']);
                          if (success) {
                            final updatedSlots = await AmsGlobals.sessionService.getTimetable(AmsGlobals.loggedInUser!.id);
                            setState(() {
                              AmsGlobals.timetableSlots.clear();
                              AmsGlobals.timetableSlots.addAll(updatedSlots);
                              _sortSlots();
                            });
                            
                            if (mounted) {
                              VesitToast.show(context: context, title: 'Slot deleted successfully!', type: ToastType.info);
                            }
                          } else {
                            if (mounted) {
                              VesitToast.show(context: context, title: 'Failed to delete slot.', type: ToastType.info);
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.error,
                          foregroundColor: context.colors.vesitWhite,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Delete', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSlotModal(Map<String, dynamic> slot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return _AddSlotModal(initialDay: slot['day'], days: _days, existingSlot: slot);
      },
    ).then((updatedSlot) async {
      if (updatedSlot != null && updatedSlot is Map<String, dynamic>) {
        if (slot['id'] == null) return;
        
        updatedSlot['facultyId'] = AmsGlobals.loggedInUser?.id;
        final error = await AmsGlobals.sessionService.updateTimetableSlot(slot['id'], updatedSlot);
        if (error == null) {
          final refreshedSlots = await AmsGlobals.sessionService.getTimetable(AmsGlobals.loggedInUser!.id);
          setState(() {
            AmsGlobals.timetableSlots.clear();
            AmsGlobals.timetableSlots.addAll(refreshedSlots);
            _sortSlots();
          });
          if (mounted) {
            VesitToast.show(context: context, title: 'Timetable slot updated!', type: ToastType.info);
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(error, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.red.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ));
          }
        }
      }
    });
  }

  String _formatTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _days.length,
      child: Scaffold(
        backgroundColor: context.colors.vesitGray,
        appBar: AppBar(
          backgroundColor: context.colors.vesitWhite,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.grey.shade600),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Timetable Manager', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary)),
          bottom: TabBar(
            isScrollable: true,
            labelColor: context.colors.vesitPrimary,
            unselectedLabelColor: Colors.grey.shade500,
            indicatorColor: context.colors.vesitPrimary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
            tabs: _days.map((day) => Tab(text: day)).toList(),
          ),
        ),
        body: TabBarView(
          children: _days.map((day) {
            final daySlots = AmsGlobals.timetableSlots.where((s) => s['day'] == day).toList();
            if (daySlots.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.weekend_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('No classes on $day.', style: context.textStyles.vesitBodyLg.copyWith(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              itemCount: daySlots.length,
              itemBuilder: (context, index) {
                final slot = daySlots[index];
                return _SlotCard(
                  slot: slot,
                  formattedStart: _formatTimeString(slot['startTime'] as String? ?? 'N/A'),
                  formattedEnd: _formatTimeString(slot['endTime'] as String? ?? 'N/A'),
                  onDelete: () => _deleteSlot(slot),
                  onEdit: () => _showEditSlotModal(slot),
                );
              },
            );
          }).toList(),
        ),
        floatingActionButton: Builder(
          builder: (ctx) {
            return FloatingActionButton.extended(
              onPressed: () {
                final tabIndex = DefaultTabController.of(ctx).index;
                _showAddSlotModal(_days[tabIndex]);
              },
              backgroundColor: context.colors.vesitPrimary,
              icon: Icon(Icons.add, color: context.colors.vesitWhite),
              label: Text('Add Slot', style: TextStyle(color: context.colors.vesitWhite, fontWeight: FontWeight.bold)),
            );
          }
        ),
      ),
    );
  }
}

class _SlotCard extends StatelessWidget {
  const _SlotCard({required this.slot, required this.formattedStart, required this.formattedEnd, required this.onDelete, required this.onEdit});
  final Map<String, dynamic> slot;
  final String formattedStart;
  final String formattedEnd;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final bool isLab = slot['type'] == 'Lab';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.colors.vesitWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      slot['subject'],
                      style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitTextHeading, fontSize: 18),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit_outlined, color: context.colors.vesitPrimary),
                        onPressed: onEdit,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline, color: context.colors.vesitRed),
                        onPressed: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text('$formattedStart  —  $formattedEnd', style: context.textStyles.vesitBodyMd.copyWith(color: Colors.grey.shade600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _Badge(label: slot['venue'], icon: Icons.room, color: context.colors.vesitPrimary),
                  const SizedBox(width: 12),
                  _Badge(label: slot['batchTarget'] ?? 'N/A', icon: Icons.people, color: AmsGlobals.getBatchColor(slot['batchTarget'] ?? '')),
                  const SizedBox(width: 12),
                  _Badge(
                    label: slot['type'], 
                    icon: isLab ? Icons.science : (slot['type'] == 'Tutorial' ? Icons.menu_book : Icons.book), 
                    color: isLab ? context.colors.vesitOrange : (slot['type'] == 'Tutorial' ? Colors.purple : context.colors.vesitGreen),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class _AddSlotModal extends StatefulWidget {
  const _AddSlotModal({required this.initialDay, required this.days, this.existingSlot});
  final String initialDay;
  final List<String> days;
  final Map<String, dynamic>? existingSlot;

  @override
  State<_AddSlotModal> createState() => _AddSlotModalState();
}

class _AddSlotModalState extends State<_AddSlotModal> {
  List<String> _subjects = ['Unknown Subject'];
  List<String> _types = ['Lecture'];
  List<String> _batches = ['Unknown Batch'];
  
  late String _day;
  String _subject = '';
  String _type = '';
  String _batch = '';
  
  final _venueController = TextEditingController();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 30);

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;
    _initScopes();

    if (widget.existingSlot != null) {
      final slot = widget.existingSlot!;
      _subject = slot['subject'] ?? _subjects.first;
      if (!_subjects.contains(_subject)) _subject = _subjects.first;
      
      _updateDependentDropdowns();

      _type = slot['type'] ?? _types.first;
      if (!_types.contains(_type)) _type = _types.first;
      
      _batch = slot['batchTarget'] ?? _batches.first;
      if (!_batches.contains(_batch)) _batch = _batches.first;
      
      _venueController.text = slot['venue'] ?? '';
      _startTime = _parseTime(slot['startTime'] ?? '09:00 AM');
      _endTime = _parseTime(slot['endTime'] ?? '10:30 AM');
    }
  }

  void _initScopes() {
    final scopes = AmsGlobals.loggedInUser?.scopes ?? [];
    if (scopes.isNotEmpty) {
      _subjects = scopes.map((s) => s['subject'] as String).toSet().toList()..sort();
      _subject = _subjects.isNotEmpty ? _subjects.first : '';
      _updateDependentDropdowns();
    }
    if (_subjects.isEmpty) _subjects = ['Unknown Subject'];
    if (_subject.isEmpty) _subject = _subjects.first;
  }

  void _updateDependentDropdowns() {
    final scopes = AmsGlobals.loggedInUser?.scopes ?? [];
    final subjectScopes = scopes.where((s) => s['subject'] == _subject).toList();
    
    if (subjectScopes.isNotEmpty) {
      _types = subjectScopes.map((s) => s['type'] as String).toSet().toList()..sort();
      if (!_types.contains(_type)) _type = _types.isNotEmpty ? _types.first : 'Lecture';
      
      _updateBatchesForType();
    } else {
      _types = ['Lecture'];
      _type = 'Lecture';
      _batches = ['Unknown Batch'];
      _batch = 'Unknown Batch';
    }
  }

  void _updateBatchesForType() {
    final scopes = AmsGlobals.loggedInUser?.scopes ?? [];
    final validScopes = scopes.where((s) => s['subject'] == _subject && s['type'] == _type).toList();
    
    if (validScopes.isNotEmpty) {
      _batches = validScopes.map((s) => s['batchTarget'] as String).toSet().toList()..sort();
      if (!_batches.contains(_batch)) {
        if (_type.toLowerCase() == 'lecture') {
          // Prefer 'All' for lectures
          final allBatch = _batches.where((b) => b.toLowerCase().contains('all')).firstOrNull;
          _batch = allBatch ?? (_batches.isNotEmpty ? _batches.first : 'Unknown Batch');
        } else {
          _batch = _batches.isNotEmpty ? _batches.first : 'Unknown Batch';
        }
      }
    } else {
      _batches = ['Unknown Batch'];
      _batch = 'Unknown Batch';
    }
  }

  TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      int hr = int.parse(timeParts[0]);
      final int min = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hr < 12) hr += 12;
      if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hr == 12) hr = 0;
      return TimeOfDay(hour: hr, minute: min);
    } catch (e) {
      return const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _venueController.dispose();
    super.dispose();
  }

  void _save() {
    // UI Validation - 2 sec top snackbar
    if (_batch.contains('ADMT') && !_subject.toLowerCase().contains('admt') && !_subject.toLowerCase().contains('database')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mismatch: Target is ADMT but Subject is not.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
          dismissDirection: DismissDirection.up,
        ),
      );
      return;
    }
    if (_batch.contains('Soft Computing') && !_subject.toLowerCase().contains('soft')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mismatch: Target is Soft Computing but Subject is not.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(top: 50, left: 20, right: 20),
          dismissDirection: DismissDirection.up,
        ),
      );
      return;
    }

    // Auto-calculate end time based on type (Lecture = 1 hr, Lab = 2 hrs)
    final durationHrs = _type == 'Lab' ? 2 : 1;
    
    int eHour = _startTime.hour + durationHrs;
    int eMin = _startTime.minute;
    if (eHour >= 24) {
      eHour -= 24;
    }
    
    final computedEndTime = TimeOfDay(hour: eHour, minute: eMin);

    Navigator.of(context).pop({
      'day': _day,
      'subject': _subject,
      'batchTarget': _batch,
      'type': _type,
      'venue': _venueController.text.isNotEmpty ? _venueController.text : 'TBA',
      'startTime': _formatTimeForBackend(_startTime),
      'endTime': _formatTimeForBackend(computedEndTime),
    });
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTimeForBackend(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _formatTimeForUi(TimeOfDay t) {
    int h = t.hour;
    final m = t.minute.toString().padLeft(2, '0');
    final amPm = h >= 12 ? 'PM' : 'AM';
    if (h > 12) h -= 12;
    if (h == 0) h = 12;
    return '$h:$m $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.vesitWhite.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, -10))],
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 24),
              Text(widget.existingSlot == null ? 'Add Timetable Slot' : 'Edit Timetable Slot', style: context.textStyles.vesitHeadlineSm.copyWith(color: context.colors.vesitPrimary)),
              const SizedBox(height: 24),

              VesitDropdown<String>(
                label: 'Day of the Week',
                icon: Icons.calendar_today,
                value: _day,
                items: widget.days,
                itemLabel: (v) => v,
                onChanged: (v) => setState(() => _day = v!),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _PickerRow(icon: Icons.schedule, label: 'Start Time', value: _formatTimeForUi(_startTime), onTap: () => _pickTime(true))),
                ],
              ),
              const SizedBox(height: 16),

              VesitDropdown<String>(
                label: 'Subject',
                icon: Icons.book_outlined,
                value: _subject,
                items: _subjects,
                itemLabel: (v) => v,
                onChanged: (v) {
                  setState(() {
                    _subject = v!;
                    _updateDependentDropdowns();
                  });
                },
              ),
              const SizedBox(height: 16),
              VesitDropdown<String>(
                label: 'Session Type',
                icon: Icons.category,
                value: _type,
                items: _types,
                itemLabel: (v) => v,
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _type = val;
                      _updateBatchesForType();
                    });
                  }
                },
              ),
              if (_type != 'Lecture') ...[
                const SizedBox(height: 16),
                VesitDropdown<String>(
                  label: 'Batch',
                  icon: Icons.people,
                  value: _batch,
                  items: _batches,
                  itemLabel: (v) => v,
                  onChanged: (val) {
                    if (val != null) setState(() => _batch = val);
                  },
                ),
              ],
              
              const SizedBox(height: 16),
              VesitTextField(
                controller: _venueController,
                label: 'Venue',
                icon: Icons.room,
                hint: 'e.g. Lab 402',
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.colors.vesitPrimary,
                  foregroundColor: context.colors.vesitWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save Slot', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.icon, required this.label, required this.value, required this.onTap});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: context.colors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: context.colors.onSurfaceVariant, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(value, style: context.textStyles.vesitBodyMd.copyWith(fontWeight: FontWeight.w600, color: context.colors.onSurface)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
