import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/flashlight_service.dart';

class FlashlightController extends ChangeNotifier {
  FlashlightController({required FlashlightService flashlightService})
    : _flashlightService = flashlightService;

  final FlashlightService _flashlightService;

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

  bool _hasSensorReading = false;
  bool get hasSensorReading => _hasSensorReading;

  int? _currentLux;
  int? get currentLux => _currentLux;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // Threshold central configurável nas settings.
  double _darknessThresholdLux = 20.0;
  double get darknessThresholdLux => _darknessThresholdLux;

  // Histerese:
  // liga abaixo de (threshold - margin)
  // desliga acima de (threshold + margin)
  double _hysteresisMarginLux = 5.0;
  double get hysteresisMarginLux => _hysteresisMarginLux;

  double get turnOnThresholdLux =>
      (_darknessThresholdLux - _hysteresisMarginLux).clamp(
        0.0,
        double.infinity,
      );

  double get turnOffThresholdLux =>
      _darknessThresholdLux + _hysteresisMarginLux;

  // Atrasos temporais
  Duration _turnOnDelay = const Duration(seconds: 2);
  Duration get turnOnDelay => _turnOnDelay;

  Duration _turnOffDelay = const Duration(seconds: 3);
  Duration get turnOffDelay => _turnOffDelay;

  Timer? _pendingTurnOnTimer;
  Timer? _pendingTurnOffTimer;

  Future<void> initialize() async {
    _isAvailable = await _flashlightService.isTorchAvailable();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> setDarknessThresholdLux(double value) async {
    _darknessThresholdLux = value;
    notifyListeners();

    if (_currentLux != null) {
      await updateLux(_currentLux!);
    }
  }

  void setHysteresisMarginLux(double value) {
    _hysteresisMarginLux = value;
    notifyListeners();
  }

  void setTurnOnDelay(Duration value) {
    _turnOnDelay = value;
    notifyListeners();
  }

  void setTurnOffDelay(Duration value) {
    _turnOffDelay = value;
    notifyListeners();
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

    if (!_isAvailable) {
      _errorMessage = 'Este dispositivo não tem lanterna disponível.';
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
      } else {
        await _flashlightService.disable();
      }

      _isOn = nextState;

      if (_autoModeEnabled && _hasSensorReading) {
        final bool sensorWantsOn = _sensorWantsOnForOverrideResolution();

        // Se o estado manual contrariar o sensor, o override fica ativo.
        // Se coincidir com o esperado pelo sensor, o override termina.
        _manualOverrideActive = (_isOn != sensorWantsOn);
      } else {
        _manualOverrideActive = false;
      }
    } catch (_) {
      _errorMessage = 'Não foi possível controlar a lanterna.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> updateLux(int lux) async {
    _currentLux = lux;
    _hasSensorReading = true;

    if (!_autoModeEnabled) {
      _cancelPendingTimers();
      notifyListeners();
      return;
    }

    // Se houver override manual, o automático não atua.
    // Só volta a ficar disponível quando o estado atual coincidir
    // com o que o sensor "quereria".
    if (_manualOverrideActive) {
      final bool sensorWantsOn = _sensorWantsOnForOverrideResolution();

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
    // Se está desligada, só nos interessa eventualmente ligar.
    _cancelPendingTurnOff();

    if (lux <= turnOnThresholdLux) {
      _pendingTurnOnTimer ??= Timer(_turnOnDelay, () async {
        _pendingTurnOnTimer = null;

        final currentLux = _currentLux;
        if (currentLux == null) return;
        if (!_autoModeEnabled || _manualOverrideActive) return;
        if (currentLux > turnOnThresholdLux) return;

        await _setTorchState(true);
      });
    } else {
      _cancelPendingTurnOn();
    }
  }

  void _handleAutomaticWhileFlashlightOn(int lux) {
    // Se está ligada, só nos interessa eventualmente desligar.
    _cancelPendingTurnOn();

    if (lux >= turnOffThresholdLux) {
      _pendingTurnOffTimer ??= Timer(_turnOffDelay, () async {
        _pendingTurnOffTimer = null;

        final currentLux = _currentLux;
        if (currentLux == null) return;
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
    if (currentLux == null) {
      return _isOn;
    }

    // Para resolver override, usamos uma intenção estável:
    // - abaixo do limiar de ligar => sensor quer ligada
    // - acima do limiar de desligar => sensor quer desligada
    // - na zona neutra => mantém o estado atual
    if (currentLux <= turnOnThresholdLux) return true;
    if (currentLux >= turnOffThresholdLux) return false;
    return _isOn;
  }

  Future<void> _setTorchState(bool shouldTurnOn) async {
    if (!_isAvailable || _isBusy) return;
    if (_isOn == shouldTurnOn) return;

    _isBusy = true;
    notifyListeners();

    try {
      if (shouldTurnOn) {
        await _flashlightService.enable();
        _isOn = true;
      } else {
        await _flashlightService.disable();
        _isOn = false;
      }
    } catch (_) {
      _errorMessage = 'Não foi possível atualizar a lanterna.';
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
    unawaited(turnOff());
    super.dispose();
  }
}
