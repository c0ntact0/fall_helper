import 'package:flutter/foundation.dart';

import '../../../../core/services/flashlight_service.dart';

enum FlashlightMode { manual, automatic }

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

  FlashlightMode _mode = FlashlightMode.manual;
  FlashlightMode get mode => _mode;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _isAvailable = await _flashlightService.isTorchAvailable();
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  void setMode(FlashlightMode mode) {
    _mode = mode;
    notifyListeners();
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
      if (_isOn) {
        await _flashlightService.disable();
        _isOn = false;
      } else {
        await _flashlightService.enable();
        _isOn = true;
      }
    } catch (_) {
      _errorMessage = 'Não foi possível controlar a lanterna.';
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> setAutomaticState(bool shouldTurnOn) async {
    if (_isBusy) return;
    if (!_isAvailable) return;
    if (_mode != FlashlightMode.automatic) return;
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
