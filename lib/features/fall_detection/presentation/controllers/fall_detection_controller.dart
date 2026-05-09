import 'package:flutter/foundation.dart';

import '../../domain/models/fall_event.dart';
import '../../services/fall_detection_service.dart';

import '../../../../core/logging/app_logger.dart';

class FallDetectionController extends ChangeNotifier {
  FallDetectionController({
    required FallDetectionService fallDetectionService,
    required AppLogger logger,
    }):
     _fallDetectionService = fallDetectionService,
     _logger = logger;

  final FallDetectionService _fallDetectionService;
  final AppLogger _logger;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  bool _isProcessingAlert = false;
  bool get isProcessingAlert => _isProcessingAlert;

  FallEvent? _lastFallEvent;
  FallEvent? get lastFallEvent => _lastFallEvent;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> start({required Future<void> Function() onFallDetected}) async {
    if (_isEnabled) return;

    _errorMessage = null;
    notifyListeners();

    try {
      await _fallDetectionService.start(
        onFallDetected: (event) async {
          if (_isProcessingAlert) return;

          _isProcessingAlert = true;
          _lastFallEvent = event;
          notifyListeners();

          try {
            await onFallDetected();
          } finally {
            _isProcessingAlert = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = 'Falha ao ler sensores de queda: $error';
          notifyListeners();

        },
      );

      _isEnabled = true;
      notifyListeners();
      await _logger.logSystemEvent(
        module: 'fall_detection_controller',
        action: 'fall_detection_enabled',
      );
    } catch (error) {
      _errorMessage = 'Não foi possível iniciar a deteção de quedas.';
      notifyListeners();
      await _logger.logError(
        module: 'fall_detection_controller',
        action: 'fall_detection_enable_failed',
        details: error.toString(),
      );
    }
  }

  Future<void> enable({required Future<void> Function() onFallDetected}) async {
    await start(onFallDetected: onFallDetected);
  }

  Future<void> stop() async {
    _errorMessage = null;

    await _fallDetectionService.stop();
    _isEnabled = false;
    notifyListeners();
    await _logger.logSystemEvent(
      module: 'fall_detection_controller',
      action: 'fall_detection_disabled',
    );
  }

  Future<void> disable() async {
    await stop();
  }

  Future<void> toggle({required Future<void> Function() onFallDetected}) async {
    if (_isEnabled) {
      await stop();
    } else {
      await start(onFallDetected: onFallDetected);
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> disposeAsync() async {
    await _fallDetectionService.dispose();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
