import 'log_event_type.dart';

class LogEntry {
  final DateTime timestamp;
  final String sessionId;
  final LogEventType eventType;
  final String module;
  final String action;
  final String details;

  const LogEntry({
    required this.timestamp,
    required this.sessionId,
    required this.eventType,
    required this.module,
    required this.action,
    this.details = '',
  });

  static const String csvHeader =
      'timestamp,session_id,event_type,module,action,details';

  String toCsvRow() {
    return [
      _escape(timestamp.toIso8601String()),
      _escape(sessionId),
      _escape(eventType.csvValue),
      _escape(module),
      _escape(action),
      _escape(details),
    ].join(',');
  }

  String _escape(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }
}
