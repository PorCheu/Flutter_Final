import 'dart:convert';

/// Enum for repeat frequency types
enum RepeatType {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

/// Enum for end conditions
enum EndCondition {
  never,
  onDate,
  afterOccurrences,
}

class AlertModel {
  final String id;
  final String note;
  final DateTime dateTime;
  
  // Enhanced repeat configuration
  final RepeatType repeatType;
  final List<int> weekdays; // 1=Monday, 7=Sunday (for weekly repeats)
  final int repeatInterval; // e.g., "every 2 weeks" = 2
  
  // End conditions
  final EndCondition endCondition;
  final DateTime? endDate;
  final int? endAfterOccurrences;
  
  final int offsetMinutes; // Reminder minutes before event
  final bool enabled;

  AlertModel({
    required this.id,
    required this.note,
    required this.dateTime,
    this.repeatType = RepeatType.none,
    this.weekdays = const [],
    this.repeatInterval = 1,
    this.endCondition = EndCondition.never,
    this.endDate,
    this.endAfterOccurrences,
    this.offsetMinutes = 0,
    this.enabled = true,
  });

  // ---------- JSON ----------
  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      note: json['note'] as String,
      dateTime: DateTime.parse(json['dateTime'] as String),
      repeatType: RepeatType.values.firstWhere(
        (e) => e.toString() == 'RepeatType.${json['repeatType']}',
        orElse: () => RepeatType.none,
      ),
      weekdays: json['weekdays'] != null 
          ? List<int>.from(json['weekdays'] as List)
          : [],
      repeatInterval: json['repeatInterval'] as int? ?? 1,
      endCondition: EndCondition.values.firstWhere(
        (e) => e.toString() == 'EndCondition.${json['endCondition']}',
        orElse: () => EndCondition.never,
      ),
      endDate: json['endDate'] != null 
          ? DateTime.parse(json['endDate'] as String)
          : null,
      endAfterOccurrences: json['endAfterOccurrences'] as int?,
      offsetMinutes: json['offsetMinutes'] as int? ?? 0,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'note': note,
        'dateTime': dateTime.toIso8601String(),
        'repeatType': repeatType.name,
        'weekdays': weekdays,
        'repeatInterval': repeatInterval,
        'endCondition': endCondition.name,
        'endDate': endDate?.toIso8601String(),
        'endAfterOccurrences': endAfterOccurrences,
        'offsetMinutes': offsetMinutes,
        'enabled': enabled,
      };

  // ---------- LIST HELPERS ----------
  static String encodeList(List<AlertModel> alerts) =>
      jsonEncode(alerts.map((e) => e.toJson()).toList());

  static List<AlertModel> decodeList(String jsonString) =>
      (jsonDecode(jsonString) as List)
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList();

  // ---------- BUSINESS LOGIC ----------
  
  /// Check if this alert occurs on a given day
  bool occursOn(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final alertDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    // One-time alert
    if (repeatType == RepeatType.none) {
      return d == alertDay;
    }

    // Check if date is before alert start
    if (d.isBefore(alertDay)) return false;

    // Check end condition
    if (!_isWithinEndCondition(d)) return false;

    // Check repeat pattern
    switch (repeatType) {
      case RepeatType.none:
        return d == alertDay;
        
      case RepeatType.daily:
        final daysDiff = d.difference(alertDay).inDays;
        return daysDiff % repeatInterval == 0;
        
      case RepeatType.weekly:
        if (weekdays.isEmpty) return false;
        final weeksDiff = (d.difference(alertDay).inDays / 7).floor();
        return weeksDiff % repeatInterval == 0 && weekdays.contains(d.weekday);
        
      case RepeatType.monthly:
        return d.day == alertDay.day && _monthsDifference(alertDay, d) % repeatInterval == 0;
        
      case RepeatType.yearly:
        return d.month == alertDay.month && 
               d.day == alertDay.day && 
               (d.year - alertDay.year) % repeatInterval == 0;
        
      case RepeatType.custom:
        // Custom handled similar to weekly for now
        if (weekdays.isEmpty) return false;
        return weekdays.contains(d.weekday);
    }
  }

  /// Check if date is within end condition
  bool _isWithinEndCondition(DateTime date) {
    switch (endCondition) {
      case EndCondition.never:
        return true;
      case EndCondition.onDate:
        if (endDate == null) return true;
        final endDay = DateTime(endDate!.year, endDate!.month, endDate!.day);
        return !date.isAfter(endDay);
      case EndCondition.afterOccurrences:
        // This requires calculating actual occurrences, which is complex
        // For now, we'll handle this in the notification service
        return true;
    }
  }

  /// Calculate months difference between two dates
  int _monthsDifference(DateTime start, DateTime end) {
    return (end.year - start.year) * 12 + (end.month - start.month);
  }

  /// Get a human-readable repeat description
  String get repeatDescription {
    if (repeatType == RepeatType.none) return 'Does not repeat';
    
    String base = '';
    switch (repeatType) {
      case RepeatType.daily:
        base = repeatInterval == 1 ? 'Daily' : 'Every $repeatInterval days';
        break;
      case RepeatType.weekly:
        if (weekdays.isEmpty) {
          base = repeatInterval == 1 ? 'Weekly' : 'Every $repeatInterval weeks';
        } else {
          const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
          final dayNames = weekdays.map((d) => names[d - 1]).join(', ');
          base = 'Weekly on $dayNames';
        }
        break;
      case RepeatType.monthly:
        base = repeatInterval == 1 ? 'Monthly' : 'Every $repeatInterval months';
        break;
      case RepeatType.yearly:
        base = 'Yearly';
        break;
      case RepeatType.custom:
        base = 'Custom';
        break;
      case RepeatType.none:
        return 'Does not repeat';
    }

    // Add end condition
    switch (endCondition) {
      case EndCondition.never:
        return base;
      case EndCondition.onDate:
        if (endDate != null) {
          return '$base, until ${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}';
        }
        return base;
      case EndCondition.afterOccurrences:
        if (endAfterOccurrences != null) {
          return '$base, $endAfterOccurrences times';
        }
        return base;
    }
  }

  /// Create a copy with updated fields
  AlertModel copyWith({
    String? id,
    String? note,
    DateTime? dateTime,
    RepeatType? repeatType,
    List<int>? weekdays,
    int? repeatInterval,
    EndCondition? endCondition,
    DateTime? endDate,
    int? endAfterOccurrences,
    int? offsetMinutes,
    bool? enabled,
  }) {
    return AlertModel(
      id: id ?? this.id,
      note: note ?? this.note,
      dateTime: dateTime ?? this.dateTime,
      repeatType: repeatType ?? this.repeatType,
      weekdays: weekdays ?? this.weekdays,
      repeatInterval: repeatInterval ?? this.repeatInterval,
      endCondition: endCondition ?? this.endCondition,
      endDate: endDate ?? this.endDate,
      endAfterOccurrences: endAfterOccurrences ?? this.endAfterOccurrences,
      offsetMinutes: offsetMinutes ?? this.offsetMinutes,
      enabled: enabled ?? this.enabled,
    );
  }
}
