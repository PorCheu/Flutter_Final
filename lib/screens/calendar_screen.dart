import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/storage_service.dart';

// Simple calendar screen using table_calendar. Tap a day to show alerts for that date.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focused = DateTime.now();
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focused,
            selectedDayPredicate: (day) => isSameDay(_selected, day),
            onDaySelected: (selectedDay, focusedDay) async {
              final ctx =
                  context; // capture context before awaiting async calls
              setState(() {
                _selected = selectedDay;
                _focused = focusedDay;
              });

              // Show alerts for the selected date
              final alerts = await StorageService.alertsForDate(selectedDay);
              if (!mounted) return;
              // Using the captured context here is safe for this simple app.
              // ignore: use_build_context_synchronously
              showModalBottomSheet(
                context: ctx,
                builder: (c) => SizedBox(
                  height: 300,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Alerts on ${selectedDay.year}-${selectedDay.month}-${selectedDay.day}',
                        ),
                      ),
                      Expanded(
                        child: alerts.isEmpty
                            ? const Center(
                                child: Text('No alerts on this date'),
                              )
                            : ListView.builder(
                                itemCount: alerts.length,
                                itemBuilder: (context, i) {
                                  final a = alerts[i];
                                  return ListTile(
                                    title: Text(a.note),
                                    subtitle: Text(
                                      '${a.dateTime.hour.toString().padLeft(2, '0')}:${a.dateTime.minute.toString().padLeft(2, '0')} • ${a.repeat}',
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
              defaultTextStyle: TextStyle(color: Colors.black87),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
              titleTextStyle: TextStyle(
                color: Colors.black87,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
