import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/alert_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

// Screen to add a new alert. Simple UI with note, date, time, repeat, and save.
class AddAlertScreen extends StatefulWidget {
  const AddAlertScreen({Key? key}) : super(key: key);

  @override
  State<AddAlertScreen> createState() => _AddAlertScreenState();
}

class _AddAlertScreenState extends State<AddAlertScreen> {
  final TextEditingController _noteController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _repeat = 'None';
  List<int> _selectedWeekdays = [];
  int _offsetMinutes = 0;
  late TextEditingController _offsetController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _offsetController = TextEditingController(text: _offsetMinutes.toString());
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _save() async {
    if (_noteController.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final dt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final alert = AlertModel(
      id: id,
      note: _noteController.text.trim(),
      dateTime: dt,
      repeat: _repeat,
      weekdays: _selectedWeekdays,
      offsetMinutes: _offsetMinutes,
      enabled: true,
    );

    // Save to storage
    await StorageService.addAlert(alert);

    // Schedule notification(s)
    final baseId = int.tryParse(id) ?? id.hashCode;
    final scheduledBase = dt.subtract(Duration(minutes: _offsetMinutes));
    if (_selectedWeekdays.isEmpty && _repeat == 'None') {
      await NotificationService.scheduleNotification(
        id: baseId,
        title: 'Habit Alert',
        body: alert.note,
        scheduledDate: scheduledBase,
      );
    } else {
      await NotificationService.scheduleRepeating(
        baseId: baseId,
        title: 'Habit Alert',
        body: alert.note,
        firstDate: scheduledBase,
        repeat: _repeat,
        weekdays: _selectedWeekdays,
        offsetMinutes: _offsetMinutes,
      );
    }

    setState(() => _saving = false);
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _offsetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Alert')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Note', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(hintText: 'Add a note'),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a note'
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        'Date: ${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text('Time: ${_selectedTime.format(context)}'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Repeat',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _repeat,
                items: const [
                  DropdownMenuItem(value: 'None', child: Text('None')),
                  DropdownMenuItem(value: 'Everyday', child: Text('Everyday')),
                  DropdownMenuItem(
                    value: 'Monday',
                    child: Text('Every Monday'),
                  ),
                  DropdownMenuItem(
                    value: 'Tuesday',
                    child: Text('Every Tuesday'),
                  ),
                  DropdownMenuItem(
                    value: 'Wednesday',
                    child: Text('Every Wednesday'),
                  ),
                  DropdownMenuItem(
                    value: 'Thursday',
                    child: Text('Every Thursday'),
                  ),
                  DropdownMenuItem(
                    value: 'Friday',
                    child: Text('Every Friday'),
                  ),
                  DropdownMenuItem(
                    value: 'Saturday',
                    child: Text('Every Saturday'),
                  ),
                  DropdownMenuItem(
                    value: 'Sunday',
                    child: Text('Every Sunday'),
                  ),
                  DropdownMenuItem(
                    value: 'Custom',
                    child: Text('Custom (choose days)'),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _repeat = v ?? 'None';
                  // If a single weekday was selected, set weekdays list accordingly
                  final mapping = {
                    'Monday': 1,
                    'Tuesday': 2,
                    'Wednesday': 3,
                    'Thursday': 4,
                    'Friday': 5,
                    'Saturday': 6,
                    'Sunday': 7,
                  };
                  if (mapping.containsKey(_repeat)) {
                    _selectedWeekdays = [mapping[_repeat]!];
                  } else if (_repeat == 'Everyday') {
                    _selectedWeekdays = [1, 2, 3, 4, 5, 6, 7];
                  } else if (_repeat == 'None') {
                    _selectedWeekdays = [];
                  } else if (_repeat == 'Custom') {
                    _selectedWeekdays = [];
                  }
                }),
                decoration: const InputDecoration(),
              ),

              const SizedBox(height: 8),
              const Text(
                'Reminder before time',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
                const SizedBox(height: 8),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _offsetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Enter minutes before (e.g. 5)'),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null; // allow empty = 0
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null || parsed < 0) return 'Enter a valid non-negative number';
                    return null;
                  },
                  onChanged: (v) => setState(() => _offsetMinutes = int.tryParse(v.trim()) ?? 0),
                ),

              if (_repeat == 'Custom') ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: List.generate(7, (i) {
                    final day = i + 1; // Monday=1
                    final labels = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    final selected = _selectedWeekdays.contains(day);
                    return ChoiceChip(
                      label: Text(labels[i]),
                      selected: selected,
                      onSelected: (s) {
                        setState(() {
                          if (s) {
                            _selectedWeekdays.add(day);
                          } else {
                            _selectedWeekdays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          await _save();
                        },
                  child: _saving
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
