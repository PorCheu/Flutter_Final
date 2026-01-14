import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/alert_model.dart';
import '../data/datasources/local_data_source.dart';
import '../data/repositories/alert_repository.dart';
import '../services/notification_service.dart';

// Home screen: lists alerts and allows enabling/disabling and deletion.
class HomeScreen extends StatefulWidget {
  final AlertRepository? alertRepository;

  const HomeScreen({super.key, this.alertRepository});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final AlertRepository _alertRepository;
  List<AlertModel> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _alertRepository =
        widget.alertRepository ?? AlertRepository(LocalDataSource());
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final alerts = await _alertRepository.getAllAlerts();
      if (mounted) {
        setState(() {
          _alerts = alerts;
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load alerts: $e')),
      );
    }
  }

  /// ✅ Correct navigation using named route
  Future<void> _navigateToAddAlert() async {
    final result = await Navigator.pushNamed(context, '/add');

    // Reload alerts ONLY if AddAlertScreen returned true
    if (result == true && mounted) {
      await _loadAlerts();
    }
  }

  String _formatDateTime(DateTime dt) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dt)} at ${timeFormat.format(dt)}';
  }

  Future<void> _toggleEnabled(AlertModel alert, bool value) async {
    final updated = alert.copyWith(enabled: value);

    final index = _alerts.indexWhere((a) => a.id == alert.id);
    if (index != -1) {
      setState(() => _alerts[index] = updated);
    }

    try {
      await _alertRepository.updateAlert(updated);

      if (value) {
        // Re-schedule notifications
        await NotificationService.scheduleAlertNotifications(updated);
      } else {
        // Cancel all notifications for this alert
        await NotificationService.cancelAlertNotifications(alert.id);
      }
    } catch (_) {
      if (index != -1 && mounted) {
        setState(() => _alerts[index] = alert);
      }
    }
  }

  Future<void> _deleteAlert(AlertModel alert) async {
    try {
      await _alertRepository.deleteAlert(alert.id);

      // Cancel all notifications for this alert
      await NotificationService.cancelAlertNotifications(alert.id);

      await _loadAlerts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  void _confirmDelete(AlertModel alert) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Alert'),
        content: Text('Delete "${alert.note}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteAlert(alert);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _repeatLabel(AlertModel a) {
    return a.repeatDescription;
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _alerts.where((a) => a.enabled).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit Alert'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => Navigator.pushNamed(context, '/calendar'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddAlert,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.notifications_off,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No alerts yet'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _navigateToAddAlert,
                        child: const Text('Create Alert'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text('$enabledCount enabled'),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _alerts.length,
                        itemBuilder: (context, index) {
                          final a = _alerts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            child: ListTile(
                              leading: const Icon(Icons.notifications),
                              title: Text(a.note),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_formatDateTime(a.dateTime)),
                                  const SizedBox(height: 4),
                                  Text(_repeatLabel(a)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: a.enabled,
                                    onChanged: (v) =>
                                        _toggleEnabled(a, v),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () =>
                                        _confirmDelete(a),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
