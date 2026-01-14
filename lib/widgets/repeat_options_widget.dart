import 'package:flutter/material.dart';
import '../models/alert_model.dart';

/// Widget for configuring repeat options (like Google Calendar)
class RepeatOptionsWidget extends StatelessWidget {
  final RepeatType repeatType;
  final List<int> selectedWeekdays;
  final int repeatInterval;
  final ValueChanged<RepeatType> onRepeatTypeChanged;
  final ValueChanged<List<int>> onWeekdaysChanged;
  final ValueChanged<int> onIntervalChanged;

  const RepeatOptionsWidget({
    super.key,
    required this.repeatType,
    required this.selectedWeekdays,
    required this.repeatInterval,
    required this.onRepeatTypeChanged,
    required this.onWeekdaysChanged,
    required this.onIntervalChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Repeat',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        
        // Repeat type dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<RepeatType>(
              value: repeatType,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: const [
                DropdownMenuItem(
                  value: RepeatType.none,
                  child: Text('Does not repeat'),
                ),
                DropdownMenuItem(
                  value: RepeatType.daily,
                  child: Text('Daily'),
                ),
                DropdownMenuItem(
                  value: RepeatType.weekly,
                  child: Text('Weekly'),
                ),
                DropdownMenuItem(
                  value: RepeatType.monthly,
                  child: Text('Monthly'),
                ),
                DropdownMenuItem(
                  value: RepeatType.yearly,
                  child: Text('Yearly'),
                ),
                DropdownMenuItem(
                  value: RepeatType.custom,
                  child: Text('Custom'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  onRepeatTypeChanged(value);
                }
              },
            ),
          ),
        ),

        // Show interval selector for daily/weekly/monthly
        if (repeatType == RepeatType.daily ||
            repeatType == RepeatType.weekly ||
            repeatType == RepeatType.monthly) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Repeat every'),
              const SizedBox(width: 8),
              SizedBox(
                width: 60,
                child: TextFormField(
                  initialValue: repeatInterval.toString(),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    if (parsed != null && parsed > 0) {
                      onIntervalChanged(parsed);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Text(_getIntervalLabel()),
            ],
          ),
        ],

        // Show weekday selector for weekly/custom
        if (repeatType == RepeatType.weekly || repeatType == RepeatType.custom) ...[
          const SizedBox(height: 12),
          const Text(
            'Repeat on',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _WeekdaySelector(
            selectedWeekdays: selectedWeekdays,
            onChanged: onWeekdaysChanged,
          ),
        ],
      ],
    );
  }

  String _getIntervalLabel() {
    switch (repeatType) {
      case RepeatType.daily:
        return repeatInterval == 1 ? 'day' : 'days';
      case RepeatType.weekly:
        return repeatInterval == 1 ? 'week' : 'weeks';
      case RepeatType.monthly:
        return repeatInterval == 1 ? 'month' : 'months';
      default:
        return '';
    }
  }
}

/// Weekday selector (Mon-Sun chips)
class _WeekdaySelector extends StatelessWidget {
  final List<int> selectedWeekdays;
  final ValueChanged<List<int>> onChanged;

  const _WeekdaySelector({
    required this.selectedWeekdays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(7, (index) {
        final weekdayValue = index + 1; // 1=Monday, 7=Sunday
        final isSelected = selectedWeekdays.contains(weekdayValue);

        return GestureDetector(
          onTap: () {
            final updated = List<int>.from(selectedWeekdays);
            if (isSelected) {
              updated.remove(weekdayValue);
            } else {
              updated.add(weekdayValue);
            }
            updated.sort();
            onChanged(updated);
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isSelected ? Colors.teal : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.grey.shade300,
              ),
              borderRadius: BorderRadius.circular(21),
            ),
            alignment: Alignment.center,
            child: Text(
              weekdayNames[index],
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }),
    );
  }
}
