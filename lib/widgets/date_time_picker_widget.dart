import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Reusable widget for picking date and time together
/// Displays a formatted preview and allows editing
class DateTimePickerWidget extends StatelessWidget {
  final DateTime selectedDateTime;
  final ValueChanged<DateTime> onChanged;
  final String? label;

  const DateTimePickerWidget({
    super.key,
    required this.selectedDateTime,
    required this.onChanged,
    this.label,
  });

  Future<void> _pickDateTime(BuildContext context) async {
    // Pick date first
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    if (!context.mounted) return;

    // Then pick time
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDateTime),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.teal,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    // Combine date and time
    final newDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    onChanged(newDateTime);
  }

  String _formatDateTime(DateTime dt) {
    // Format like: "Mon, Jan 15, 2026 at 9:30 AM"
    final dateFormat = DateFormat('EEE, MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dt)} at ${timeFormat.format(dt)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
        ],
        InkWell(
          onTap: () => _pickDateTime(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.teal.shade700, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _formatDateTime(selectedDateTime),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(Icons.edit, color: Colors.grey.shade600, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
