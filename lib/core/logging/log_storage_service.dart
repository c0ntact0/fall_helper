import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'log_entry.dart';

class LogStorageService {
  static const String _logsFolderName = 'logs';

  String? _currentSessionId;
  File? _currentLogFile;

  Future<String> ensureSession() async {
    _currentSessionId ??= _buildSessionId(DateTime.now());
    await _ensureLogFile();
    return _currentSessionId!;
  }

  Future<File> getCurrentLogFile() async {
    await ensureSession();
    return _currentLogFile!;
  }

  Future<Directory> getLogsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final logsDir = Directory(p.join(appDir.path, _logsFolderName));

    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }

    return logsDir;
  }

  Future<void> append(LogEntry entry) async {
    final file = await getCurrentLogFile();
    await file.writeAsString(
      '${entry.toCsvRow()}\n',
      mode: FileMode.append,
      flush: true,
    );
  }

  Future<List<FileSystemEntity>> listLogFiles() async {
    final logsDir = await getLogsDirectory();
    final items = await logsDir.list().toList();
    items.sort((a, b) => a.path.compareTo(b.path));
    return items;
  }

  Future<void> startNewSession() async {
    _currentSessionId = _buildSessionId(DateTime.now());
    _currentLogFile = null;
    await _ensureLogFile();
  }

  Future<void> _ensureLogFile() async {
    _currentSessionId ??= _buildSessionId(DateTime.now());

    if (_currentLogFile != null) {
      return;
    }

    final logsDir = await getLogsDirectory();
    final fileName = 'log_session_${_currentSessionId!}.csv';
    final file = File(p.join(logsDir.path, fileName));

    final exists = await file.exists();
    if (!exists) {
      await file.create(recursive: true);
      await file.writeAsString('${LogEntry.csvHeader}\n', flush: true);
    }

    _currentLogFile = file;
  }

  String _buildSessionId(DateTime now) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_'
        '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }
}
