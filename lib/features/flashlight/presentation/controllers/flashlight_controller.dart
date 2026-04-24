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

  bool _shouldBeOnBySensor = false;
  bool get shouldBeOnBySensor => _shouldBeOnBySensor;

  int? _currentLux;
  int? get currentLux => _currentLux;

  double _darknessThresholdLux = 20.0;
  double get darknessThresholdLux => _darknessThresholdLux;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  Future<void> setAutoModeEnabled(bool value) async {
    _autoModeEnabled = value;

    if (!_autoModeEnabled) {
      _manualOverrideActive = false;
      notifyListeners();
      return;
    }

    notifyListeners();
    await _applyAutomaticStateIfNeeded();
  }

  Future<void> toggleManual() async {
    if (_isBusy) return;

    if (!_isAvailable) {
      _errorMessage = 'Este dispositivo não tem lanterna disponível.';
      notifyListeners();
      return;
    }

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
        _manualOverrideActive = _isOn != _shouldBeOnBySensor;
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
    final shouldTurnOn = lux <= _darknessThresholdLux;

    _hasSensorReading = true;
    _shouldBeOnBySensor = shouldTurnOn;

    if (!_autoModeEnabled) {
      notifyListeners();
      return;
    }

    if (_manualOverrideActive) {
      if (_isOn == _shouldBeOnBySensor) {
        _manualOverrideActive = false;
        notifyListeners();
      }
      return;
    }

    notifyListeners();
    await _applyAutomaticStateIfNeeded();
  }

  Future<void> _applyAutomaticStateIfNeeded() async {
    if (!_autoModeEnabled) return;
    if (_manualOverrideActive) return;
    if (!_hasSensorReading) return;
    if (!_isAvailable) return;
    if (_isBusy) return;
    if (_isOn == _shouldBeOnBySensor) return;

    _isBusy = true;
    notifyListeners();

    try {
      if (_shouldBeOnBySensor) {
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

  @override
  void dispose() {
    turnOff();
    super.dispose();
  }
}
