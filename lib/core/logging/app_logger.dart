import 'package:flutter/foundation.dart';

import 'log_entry.dart';
import 'log_event_type.dart';
import 'log_storage_service.dart';

class AppLogger {
  AppLogger({
    required LogStorageService storageService,
    bool mirrorToDebugConsole = true,
  }) : _storageService = storageService,
       _mirrorToDebugConsole = mirrorToDebugConsole;

  final LogStorageService _storageService;
  final bool _mirrorToDebugConsole;

  Future<void> initialize() async {
    await _storageService.ensureSession();
    await logSystemEvent(module: 'app_logger', action: 'session_started');
  }

  Future<void> startNewSession() async {
    await _storageService.startNewSession();
    await logSystemEvent(module: 'app_logger', action: 'session_started');
  }

  Future<void> logUserAction({
    required String module,
    required String action,
    String details = '',
  }) async {
    await _log(
      eventType: LogEventType.user,
      module: module,
      action: action,
      details: details,
    );
  }

  Future<void> logSystemEvent({
    required String module,
    required String action,
    String details = '',
  }) async {
    await _log(
      eventType: LogEventType.system,
      module: module,
      action: action,
      details: details,
    );
  }

  Future<void> logError({
    required String module,
    required String action,
    String details = '',
  }) async {
    await _log(
      eventType: LogEventType.error,
      module: module,
      action: action,
      details: details,
    );
  }

  Future<void> _log({
    required LogEventType eventType,
    required String module,
    required String action,
    required String details,
  }) async {
    try {
      final sessionId = await _storageService.ensureSession();

      final entry = LogEntry(
        timestamp: DateTime.now(),
        sessionId: sessionId,
        eventType: eventType,
        module: module,
        action: action,
        details: details,
      );

      await _storageService.append(entry);

      if (_mirrorToDebugConsole) {
        debugPrint(
          '[LOG] ${entry.timestamp.toIso8601String()} '
          '[${entry.eventType.csvValue}] '
          '[$module] $action'
          '${details.isNotEmpty ? ' | $details' : ''}',
        );
      }
    } catch (error) {
      if (_mirrorToDebugConsole) {
        debugPrint('Falha ao escrever log: $error');
      }
    }
  }
}
