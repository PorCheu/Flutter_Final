import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';

/// Widget for configuring end conditions (Never / On date / After N occurrences)
class EndConditionWidget extends StatelessWidget {
  final EndCondition endCondition;
  final DateTime? endDate;
  final int? endAfterOccurrences;
  final ValueChanged<EndCondition> onEndConditionChanged;
  final ValueChanged<DateTime?> onEndDateChanged;
  final ValueChanged<int?> onOccurrencesChanged;

  const EndConditionWidget({
    super.key,
    required this.endCondition,
    this.endDate,
    this.endAfterOccurrences,
    required this.onEndConditionChanged,
    required this.onEndDateChanged,
    required this.onOccurrencesChanged,
  });

  Future<void> _pickEndDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
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

    if (picked != null) {
      onEndDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ends',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),

        // Never option
        RadioListTile<EndCondition>(
          value: EndCondition.never,
          groupValue: endCondition,
          title: const Text('Never'),
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.teal,
          onChanged: (value) {
            if (value != null) {
              onEndConditionChanged(value);
            }
          },
        ),

        // On date option
        RadioListTile<EndCondition>(
          value: EndCondition.onDate,
          groupValue: endCondition,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.teal,
          title: Row(
            children: [
              const Text('On'),
              const SizedBox(width: 8),
              if (endCondition == EndCondition.onDate) ...[
                Expanded(
                  child: GestureDetector(
                    onTap: () => _pickEndDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            endDate != null
                                ? DateFormat('MMM d, yyyy').format(endDate!)
                                : 'Select date',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.calendar_today, size: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          onChanged: (value) {
            if (value != null) {
              onEndConditionChanged(value);
              // Set default end date if not set
              if (endDate == null) {
                onEndDateChanged(DateTime.now().add(const Duration(days: 30)));
              }
            }
          },
        ),

        // After N occurrences option
        RadioListTile<EndCondition>(
          value: EndCondition.afterOccurrences,
          groupValue: endCondition,
          contentPadding: EdgeInsets.zero,
          activeColor: Colors.teal,
          title: Row(
            children: [
              const Text('After'),
              const SizedBox(width: 8),
              if (endCondition == EndCondition.afterOccurrences) ...[
                SizedBox(
                  width: 70,
                  child: TextFormField(
                    initialValue: endAfterOccurrences?.toString() ?? '10',
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    onChanged: (value) {
                      final parsed = int.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        onOccurrencesChanged(parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text('occurrences'),
              ],
            ],
          ),
          onChanged: (value) {
            if (value != null) {
              onEndConditionChanged(value);
              // Set default occurrences if not set
              if (endAfterOccurrences == null) {
                onOccurrencesChanged(10);
              }
            }
          },
        ),
      ],
    );
  }
}
