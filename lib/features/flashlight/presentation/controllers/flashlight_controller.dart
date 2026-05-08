import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/flashlight_service.dart';
import '../../../../core/services/voice_alert_service.dart';

import '../../../../core/logging/app_logger.dart';

class FlashlightController extends ChangeNotifier {
  FlashlightController({
    required FlashlightService flashlightService,
    required VoiceAlertService voiceAlertService,
    required AppLogger logger,
    }) :  _flashlightService = flashlightService,
          _voiceAlertService = voiceAlertService,
          _logger = logger;

  final FlashlightService _flashlightService;
  final VoiceAlertService _voiceAlertService;
  final AppLogger _logger;

  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;

  bool _isOn = false;
  bool get isOn => _isOn;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  bool _autoModeEnabled = false;
  bool get autoModeEnabled => _autoModeEnabled;

  bool _manualOverrideActive = false;
  bool get manualOverrideActive => _manualOverrideActive;

  bool _blockedByVideoRecording = false;
  bool get blockedByVideoRecording => _blockedByVideoRecording;

  bool get canUseFlashlight => _isAvailable && !_blockedByVideoRecording;

  int? _currentLux;
  int? get currentLux => _currentLux;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  double _darknessThresholdLux = 20.0;
  double get darknessThresholdLux => _darknessThresholdLux;

  final double _hysteresisMarginLux = 5.0;
  double get hysteresisMarginLux => _hysteresisMarginLux;

  double get turnOnThresholdLux =>
      (_darknessThresholdLux - _hysteresisMarginLux).clamp(
        0.0,
        double.infinity,
      );

  double get turnOffThresholdLux =>
      _darknessThresholdLux + _hysteresisMarginLux;

  final Duration _turnOnDelay = const Duration(seconds: 2);
  final Duration _turnOffDelay = const Duration(seconds: 3);

  Timer? _pendingTurnOnTimer;
  Timer? _pendingTurnOffTimer;

  Future<void> initialize() async {
    _isAvailable = await _flashlightService.isTorchAvailable();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> setBlockedByVideoRecording(bool value) async {
    _blockedByVideoRecording = value;

    if (value) {
      _cancelPendingTimers();
      _manualOverrideActive = false;

      if (_isOn) {
        try {
          await _flashlightService.disable();
          _isOn = false;
          _logger.logSystemEvent(
            module: 'flashlight_controller', 
            action: 'blocked_by_video_recording'
            );
        } catch (_) {}
      }
    }

    notifyListeners();
  }

  Future<void> setDarknessThresholdLux(double value) async {
    _darknessThresholdLux = value;
    notifyListeners();

    if (_currentLux != null) {
      await updateLux(_currentLux!);
    }
  }

  Future<void> setAutoModeEnabled(bool value) async {
    _autoModeEnabled = value;

    if (!_autoModeEnabled) {
      _manualOverrideActive = false;
      _cancelPendingTimers();
      notifyListeners();
      return;
    }

    notifyListeners();

    if (_currentLux != null) {
      await updateLux(_currentLux!);
    }
  }

  Future<void> toggleManual() async {
    if (_isBusy) return;

    if (!canUseFlashlight) {
      _errorMessage = _blockedByVideoRecording
          ? 'Lanterna indisponível durante a gravação de vídeo.'
          : 'Este dispositivo não tem lanterna disponível.';
      notifyListeners();
      return;
    }

    _cancelPendingTimers();

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final nextState = !_isOn;

      if (nextState) {
        await _flashlightService.enable();
        await _voiceAlertService.speakFlashlightOn();
        _logger.logUserAction(
          module: 'flashlight_controller', 
          action: 'flashlight_on'
          );
      } else {
        await _flashlightService.disable();
        await _voiceAlertService.speakFlashlightOff();
        _logger.logUserAction(
          module: 'flashlight_controller',
          action: 'flashlight_off',
        );
      }

      _isOn = nextState;

      if (_autoModeEnabled && _currentLux != null) {
        final sensorWantsOn = _sensorWantsOnForOverrideResolution();
        _manualOverrideActive = (_isOn != sensorWantsOn);
      } else {
        _manualOverrideActive = false;
      }
    } catch (_) {
      _errorMessage = 'Não foi possível controlar a lanterna.';
      _logger.logError(module: 'flashlight_controller', action: 'failed_to_control_flashlight');
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateLux(int lux) async {
    _currentLux = lux;

    if (_blockedByVideoRecording) {
      _cancelPendingTimers();
      notifyListeners();
      return;
    }

    if (!_autoModeEnabled) {
      _cancelPendingTimers();
      notifyListeners();
      return;
    }

    if (_manualOverrideActive) {
      final sensorWantsOn = _sensorWantsOnForOverrideResolution();

      if (_isOn == sensorWantsOn) {
        _manualOverrideActive = false;
      }

      notifyListeners();
      return;
    }

    if (_isOn) {
      _handleAutomaticWhileFlashlightOn(lux);
    } else {
      _handleAutomaticWhileFlashlightOff(lux);
    }

    notifyListeners();
  }

  void _handleAutomaticWhileFlashlightOff(int lux) {
    _cancelPendingTurnOff();

    if (lux <= turnOnThresholdLux) {
      _pendingTurnOnTimer ??= Timer(_turnOnDelay, () async {
        _pendingTurnOnTimer = null;

        final currentLux = _currentLux;
        if (currentLux == null) return;
        if (_blockedByVideoRecording) return;
        if (!_autoModeEnabled || _manualOverrideActive) return;
        if (currentLux > turnOnThresholdLux) return;

        await _setTorchState(true);
      });
    } else {
      _cancelPendingTurnOn();
    }
  }

  void _handleAutomaticWhileFlashlightOn(int lux) {
    _cancelPendingTurnOn();

    if (lux >= turnOffThresholdLux) {
      _pendingTurnOffTimer ??= Timer(_turnOffDelay, () async {
        _pendingTurnOffTimer = null;

        final currentLux = _currentLux;
        if (currentLux == null) return;
        if (_blockedByVideoRecording) return;
        if (!_autoModeEnabled || _manualOverrideActive) return;
        if (currentLux < turnOffThresholdLux) return;

        await _setTorchState(false);
      });
    } else {
      _cancelPendingTurnOff();
    }
  }

  bool _sensorWantsOnForOverrideResolution() {
    final currentLux = _currentLux;
    if (currentLux == null) return _isOn;

    if (currentLux <= turnOnThresholdLux) return true;
    if (currentLux >= turnOffThresholdLux) return false;
    return _isOn;
  }

  Future<void> _setTorchState(bool shouldTurnOn) async {
    if (!canUseFlashlight || _isBusy) return;
    if (_isOn == shouldTurnOn) return;

    _isBusy = true;
    notifyListeners();

    try {
      if (shouldTurnOn) {
        await _flashlightService.enable();
        _isOn = true;
        await _voiceAlertService.speakFlashlightOn();
        _logger.logSystemEvent(
          module: 'flashlight_controller', 
          action: 'automatic_flashlight_on'
          );
      } else {
        await _flashlightService.disable();
        _isOn = false;
        await _voiceAlertService.speakFlashlightOff();
        _logger.logSystemEvent(
          module: 'flashlight_controller',
          action: 'automatic_flashlight_off',
        );
      }
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar a lanterna.';
      _logger.logError(
        module: 'flashlight_controller',
        action: 'automatic_flashlight_failed',
      );
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> turnOff() async {
    _cancelPendingTimers();

    if (!_isOn) return;

    try {
      await _flashlightService.disable();
      _isOn = false;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Não foi possível desligar a lanterna.';
      notifyListeners();
    }
  }

  void _cancelPendingTurnOn() {
    _pendingTurnOnTimer?.cancel();
    _pendingTurnOnTimer = null;
  }

  void _cancelPendingTurnOff() {
    _pendingTurnOffTimer?.cancel();
    _pendingTurnOffTimer = null;
  }

  void _cancelPendingTimers() {
    _cancelPendingTurnOn();
    _cancelPendingTurnOff();
  }

  @override
  void dispose() {
    _cancelPendingTimers();
    turnOff();
    super.dispose();
  }
}
