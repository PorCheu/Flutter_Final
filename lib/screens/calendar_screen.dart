import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../data/datasources/local_data_source.dart';
import '../data/repositories/alert_repository.dart';
import '../models/alert_model.dart';

// Calendar screen showing alerts per day
class CalendarScreen extends StatefulWidget {
  final AlertRepository? alertRepository;

  const CalendarScreen({super.key, this.alertRepository});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late final AlertRepository _alertRepository;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<AlertModel> _allAlerts = [];

  @override
  void initState() {
    super.initState();
    _alertRepository =
        widget.alertRepository ?? AlertRepository(LocalDataSource());
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final alerts = await _alertRepository.getAllAlerts();
      if (mounted) {
        setState(() => _allAlerts = alerts);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load alerts: $e')),
      );
    }
  }

  List<AlertModel> _eventsForDay(DateTime day) {
    return _allAlerts
        .where((a) => a.enabled && a.occursOn(day))
        .toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;
    final events = _eventsForDay(selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.pushNamed(context, '/add');
          if (result == true && mounted) {
            await _loadAlerts();
          }
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2000, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _eventsForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.tealAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.teal,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  '${events.length} alerts',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          /// ✅ SAFE scrollable area
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: events.isEmpty
                  ? const Center(
                      key: ValueKey('empty'),
                      child: Text('No alerts on this date'),
                    )
                  : ListView.builder(
                      key: const ValueKey('list'),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: events.length,
                      itemBuilder: (context, index) {
                        final a = events[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(Icons.notifications),
                            title: Text(a.note),
                            subtitle: Text(
                              '${a.dateTime.hour.toString().padLeft(2, '0')}:'
                              '${a.dateTime.minute.toString().padLeft(2, '0')} • '
                              '${a.repeatDescription}',
                            ),
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (c) => Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        a.note,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'When: '
                                        '${a.dateTime.year}-'
                                        '${a.dateTime.month.toString().padLeft(2, '0')}-'
                                        '${a.dateTime.day.toString().padLeft(2, '0')} '
                                        '${a.dateTime.hour.toString().padLeft(2, '0')}:'
                                        '${a.dateTime.minute.toString().padLeft(2, '0')}',
                                      ),
                                      const SizedBox(height: 8),
                                      Text('Repeat: ${a.repeatDescription}'),
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(c),
                                          child: const Text('Close'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.teal,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Days with alerts are marked'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
