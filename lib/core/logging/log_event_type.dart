enum LogEventType { user, system, error }

extension LogEventTypeCsv on LogEventType {
  String get csvValue {
    switch (this) {
      case LogEventType.user:
        return 'user';
      case LogEventType.system:
        return 'system';
      case LogEventType.error:
        return 'error';
    }
  }
}
