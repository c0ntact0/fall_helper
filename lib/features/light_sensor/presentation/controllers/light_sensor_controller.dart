import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/light_sensor_service.dart';

class LightSensorController extends ChangeNotifier {
  LightSensorController({required LightSensorService lightSensorService})
    : _lightSensorService = lightSensorService;

  final LightSensorService _lightSensorService;

  StreamSubscription<int>? _subscription;

  bool _isListening = false;
  bool get isListening => _isListening;

  int? _currentLux;
  int? get currentLux => _currentLux;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> startListening({void Function(int lux)? onLuxChanged}) async {
    if (_isListening) return;

    try {
      await _lightSensorService.requestAuthorization();

      _subscription = _lightSensorService.lightStream.listen(
        (lux) {
          _currentLux = lux;
          notifyListeners();

          if (onLuxChanged != null) {
            onLuxChanged(lux);
          }
        },
        onError: (_) {
          _errorMessage = 'Não foi possível ler o sensor de luminosidade.';
          notifyListeners();
        },
      );

      _isListening = true;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Falha ao iniciar sensor de luminosidade.';
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
