import 'package:flutter/material.dart';
import '../models/alert_model.dart';
import '../data/datasources/local_data_source.dart';
import '../data/repositories/alert_repository.dart';
import '../services/notification_service.dart';
import '../widgets/date_time_picker_widget.dart';
import '../widgets/repeat_options_widget.dart';
import '../widgets/end_condition_widget.dart';

/// Enhanced Add Alert Screen with Google Calendar-style scheduling
class AddAlertScreen extends StatefulWidget {
  final AlertRepository? alertRepository;

  const AddAlertScreen({super.key, this.alertRepository});

  @override
  State<AddAlertScreen> createState() => _AddAlertScreenState();
}

class _AddAlertScreenState extends State<AddAlertScreen> {
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _offsetController = TextEditingController(text: '15');
  final _formKey = GlobalKey<FormState>();

  // Date & Time
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 1));

  // Repeat configuration
  RepeatType _repeatType = RepeatType.none;
  List<int> _selectedWeekdays = [];
  int _repeatInterval = 1;

  // End condition
  EndCondition _endCondition = EndCondition.never;
  DateTime? _endDate;
  int? _endAfterOccurrences;

  // Reminder offset
  int _offsetMinutes = 15;

  late final AlertRepository _alertRepository;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _alertRepository = widget.alertRepository ?? AlertRepository(LocalDataSource());
    
    // Round to next 15-minute interval
    final now = DateTime.now();
    final roundedMinute = ((now.minute / 15).ceil() * 15) % 60;
    final addHour = roundedMinute == 0 ? 1 : 0;
    _selectedDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour + addHour + 1,
      roundedMinute,
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate past date
    if (_selectedDateTime.isBefore(DateTime.now())) {
      _showError('Cannot schedule alerts in the past');
      return;
    }

    // Validate weekdays for weekly repeat
    if (_repeatType == RepeatType.weekly && _selectedWeekdays.isEmpty) {
      _showError('Please select at least one weekday');
      return;
    }

    // Validate end date
    if (_endCondition == EndCondition.onDate && _endDate != null) {
      if (_endDate!.isBefore(_selectedDateTime)) {
        _showError('End date must be after start date');
        return;
      }
    }

    setState(() => _saving = true);

    final alert = AlertModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      note: _noteController.text.trim(),
      dateTime: _selectedDateTime,
      repeatType: _repeatType,
      weekdays: _selectedWeekdays,
      repeatInterval: _repeatInterval,
      endCondition: _endCondition,
      endDate: _endDate,
      endAfterOccurrences: _endAfterOccurrences,
      offsetMinutes: _offsetMinutes,
      enabled: true,
    );

    try {
      await _alertRepository.createAlert(alert);

      // Schedule notifications
      await NotificationService.scheduleAlertNotifications(alert);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        _showError('Failed to save alert: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Habit Alert'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Habit note input
                      const Text(
                        'Habit Note',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Take medication, Drink water, Exercise',
                          prefixIcon: Icon(Icons.note_outlined),
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty
                                ? 'Please enter a habit note'
                                : null,
                        textInputAction: TextInputAction.next,
                      ),

                      const SizedBox(height: 24),

                      // Date & Time picker
                      DateTimePickerWidget(
                        label: 'Date & Time',
                        selectedDateTime: _selectedDateTime,
                        onChanged: (dt) => setState(() => _selectedDateTime = dt),
                      ),

                      const SizedBox(height: 24),

                      // Repeat options
                      RepeatOptionsWidget(
                        repeatType: _repeatType,
                        selectedWeekdays: _selectedWeekdays,
                        repeatInterval: _repeatInterval,
                        onRepeatTypeChanged: (type) {
                          setState(() {
                            _repeatType = type;
                            // Reset weekdays if not weekly/custom
                            if (type != RepeatType.weekly && type != RepeatType.custom) {
                              _selectedWeekdays = [];
                            }
                          });
                        },
                        onWeekdaysChanged: (days) {
                          setState(() => _selectedWeekdays = days);
                        },
                        onIntervalChanged: (interval) {
                          setState(() => _repeatInterval = interval);
                        },
                      ),

                      // End conditions (show only if repeating)
                      if (_repeatType != RepeatType.none) ...[
                        const SizedBox(height: 24),
                        EndConditionWidget(
                          endCondition: _endCondition,
                          endDate: _endDate,
                          endAfterOccurrences: _endAfterOccurrences,
                          onEndConditionChanged: (condition) {
                            setState(() => _endCondition = condition);
                          },
                          onEndDateChanged: (date) {
                            setState(() => _endDate = date);
                          },
                          onOccurrencesChanged: (count) {
                            setState(() => _endAfterOccurrences = count);
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Reminder offset
                      const Text(
                        'Reminder',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('Remind me'),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: TextFormField(
                              controller: _offsetController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 8,
                                ),
                              ),
                              onChanged: (v) {
                                final parsed = int.tryParse(v);
                                if (parsed != null && parsed >= 0) {
                                  _offsetMinutes = parsed;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text('minutes before'),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Preview summary
                      _buildPreviewSummary(),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // Bottom action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Save Alert'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewSummary() {
    if (_noteController.text.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 18, color: Colors.teal.shade700),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.teal.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _buildPreviewText(),
            style: TextStyle(
              fontSize: 13,
              color: Colors.teal.shade900,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _buildPreviewText() {
    final buffer = StringBuffer();
    
    buffer.write('You will receive a notification ');
    
    if (_offsetMinutes > 0) {
      buffer.write('$_offsetMinutes minutes before ');
    }
    
    buffer.write('"${_noteController.text.trim()}"');
    
    if (_repeatType == RepeatType.none) {
      buffer.write(' on ${_formatShortDateTime(_selectedDateTime)}.');
    } else {
      buffer.write(', repeating ');
      
      switch (_repeatType) {
        case RepeatType.daily:
          buffer.write(_repeatInterval == 1 ? 'daily' : 'every $_repeatInterval days');
          break;
        case RepeatType.weekly:
          if (_selectedWeekdays.isNotEmpty) {
            const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final dayNames = _selectedWeekdays.map((d) => names[d - 1]).join(', ');
            buffer.write('weekly on $dayNames');
          }
          break;
        case RepeatType.monthly:
          buffer.write(_repeatInterval == 1 ? 'monthly' : 'every $_repeatInterval months');
          break;
        case RepeatType.yearly:
          buffer.write('yearly');
          break;
        default:
          break;
      }
      
      // Add end condition
      switch (_endCondition) {
        case EndCondition.never:
          buffer.write(' (forever)');
          break;
        case EndCondition.onDate:
          if (_endDate != null) {
            buffer.write(' until ${_formatShortDate(_endDate!)}');
          }
          break;
        case EndCondition.afterOccurrences:
          if (_endAfterOccurrences != null) {
            buffer.write(' $_endAfterOccurrences times');
          }
          break;
      }
      
      buffer.write('.');
    }
    
    return buffer.toString();
  }

  String _formatShortDateTime(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, $hour:$minute $ampm';
  }

  String _formatShortDate(DateTime dt) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}
