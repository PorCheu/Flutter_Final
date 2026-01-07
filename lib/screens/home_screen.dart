import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../models/alert_model.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';

// Home screen: lists alerts and allows enabling/disabling and deletion.
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() => _loading = true);
    final alerts = await StorageService.loadAlerts();
    setState(() {
      _alerts = alerts;
      _loading = false;
    });
  }

  String _formatDateTime(DateTime dt) {
    final d = dt.toLocal();
    final date =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final time =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }

  Future<void> _toggleEnabled(AlertModel alert, bool value) async {
    final updated = AlertModel(
      id: alert.id,
      note: alert.note,
      dateTime: alert.dateTime,
      repeat: alert.repeat,
      weekdays: alert.weekdays,
      offsetMinutes: alert.offsetMinutes,
      enabled: value,
    );
    await StorageService.updateAlert(updated);

    final baseId = int.tryParse(alert.id) ?? alert.id.hashCode;
    if (value) {
      // Schedule notifications
      final scheduledBase = alert.dateTime.subtract(
        Duration(minutes: alert.offsetMinutes),
      );
      if ((alert.weekdays.isEmpty) && alert.repeat == 'None') {
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
          repeat: alert.repeat,
          weekdays: alert.weekdays,
          offsetMinutes: alert.offsetMinutes,
        );
      }
    } else {
      // Cancel notifications
      await NotificationService.cancel(baseId);
      await NotificationService.cancelRepeating(baseId, alert.repeat);
    }

    _loadAlerts();
  }

  Future<void> _deleteAlert(AlertModel alert) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Alert'),
        content: const Text('Are you sure you want to delete this alert?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.deleteAlert(alert.id);
      final baseId = int.tryParse(alert.id) ?? alert.id.hashCode;
      await NotificationService.cancel(baseId);
      await NotificationService.cancelRepeating(baseId, alert.repeat);
      _loadAlerts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Alert'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today, color: Colors.black87),
            onPressed: () => Navigator.pushNamed(context, '/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black87),
            onPressed: () async {
              await Navigator.pushNamed(context, '/add');
              _loadAlerts();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No alerts yet',
                    style: TextStyle(color: Colors.grey[700], fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await Navigator.pushNamed(context, '/add');
                      _loadAlerts();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Alert'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: _alerts.length,
              itemBuilder: (context, index) {
                final a = _alerts[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    title: Text(
                      a.note,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      '${_formatDateTime(a.dateTime)} • ${_repeatLabel(a)}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: a.enabled,
                          onChanged: (v) => _toggleEnabled(a, v),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => _deleteAlert(a),
                          tooltip: 'Delete',
                        ),
                      ],
                    ),
                    onTap: () => _toggleEnabled(a, !a.enabled),
                  ),
                );
              },
            ),
    );
  }

  String _repeatLabel(AlertModel a) {
    String repeatPart;
    if (a.weekdays.isNotEmpty) {
      if (a.weekdays.length == 7) {
        repeatPart = 'Everyday';
      } else {
        final names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        repeatPart = a.weekdays.map((d) => names[d - 1]).join(', ');
      }
    } else {
      repeatPart = a.repeat;
    }

    if (a.offsetMinutes > 0) {
      return '$repeatPart • ${a.offsetMinutes}m before';
    }
    return repeatPart;
  }
}
