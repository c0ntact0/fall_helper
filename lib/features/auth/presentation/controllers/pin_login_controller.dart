import 'package:flutter/foundation.dart';

import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/validators.dart';

class PinLoginController extends ChangeNotifier {
  PinLoginController({required StorageService storageService})
    : _storageService = storageService;

  static const int pinLength = 4;

  final StorageService _storageService;

  String _enteredPin = '';
  String get enteredPin => _enteredPin;

  String _savedPin = '0000';
  String get savedPin => _savedPin;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    final caregiver = await _storageService.loadCaregiver();
    _savedPin = caregiver.pin;
    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  void onDigitPressed(String digit) {
    if (_isLoading) return;
    if (_enteredPin.length >= pinLength) return;

    _enteredPin += digit;
    _errorMessage = null;
    notifyListeners();
  }

  void onBackspacePressed() {
    if (_isLoading) return;
    if (_enteredPin.isEmpty) return;

    _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
    _errorMessage = null;
    notifyListeners();
  }

  bool get shouldValidateNow => _enteredPin.length == pinLength;

  bool validatePin() {
    final validationError = AppValidators.pin4Digits(_enteredPin);

    if (validationError != null) {
      _enteredPin = '';
      _errorMessage = validationError;
      notifyListeners();
      return false;
    }

    if (_enteredPin == _savedPin) {
      _errorMessage = null;
      notifyListeners();
      return true;
    }

    _enteredPin = '';
    _errorMessage = 'PIN incorreto';
    notifyListeners();
    return false;
  }
}
