import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../settings/domain/models/caregiver.dart';
import '../../../settings/domain/models/user_feature_settings.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required StorageService storageService,
    required PhoneCallService phoneCallService,
  }) : _storageService = storageService,
       _phoneCallService = phoneCallService;

  final StorageService _storageService;
  final PhoneCallService _phoneCallService;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isFallDetectionActive = true;
  bool get isFallDetectionActive => _isFallDetectionActive;

  bool _isFlashlightActive = false;
  bool get isFlashlightActive => _isFlashlightActive;

  bool _isPanicInProgress = false;
  bool get isPanicInProgress => _isPanicInProgress;

  double _panicProgress = 0.0;
  double get panicProgress => _panicProgress;

  bool _showFallDetectionButton = true;
  bool get showFallDetectionButton => _showFallDetectionButton;

  bool _showPanicButton = true;
  bool get showPanicButton => _showPanicButton;

  String _caregiverName = 'Cuidador';
  String get caregiverName => _caregiverName;

  String _caregiverPhoneNumber = '';
  String get caregiverPhoneNumber => _caregiverPhoneNumber;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Timer? _panicTimer;

  Future<void> loadHomeSettings() async {
    final Caregiver caregiver = await _storageService.loadCaregiver();
    final UserFeatureSettings userFeatureSettings = await _storageService
        .loadUserFeatureSettings();

    _caregiverName = caregiver.name;
    _caregiverPhoneNumber = caregiver.phoneNumber;
    _showFallDetectionButton = userFeatureSettings.showFallDetectionButton;
    _showPanicButton = userFeatureSettings.showPanicButton;
    _isLoading = false;

    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  void toggleFallDetection() {
    _isFallDetectionActive = !_isFallDetectionActive;
    notifyListeners();
  }

  void toggleFlashlight() {
    _isFlashlightActive = !_isFlashlightActive;
    notifyListeners();
  }

  void startPanicFlow() {
    if (_isPanicInProgress) return;

    if (_caregiverPhoneNumber.trim().isEmpty) {
      _errorMessage = 'Configure o telefone do cuidador primeiro.';
      notifyListeners();
      return;
    }

    _isPanicInProgress = true;
    _panicProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    const totalDuration = Duration(seconds: 5);
    const stepDuration = Duration(milliseconds: 100);

    final int totalSteps =
        totalDuration.inMilliseconds ~/ stepDuration.inMilliseconds;

    int currentStep = 0;

    _panicTimer?.cancel();
    _panicTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;
      _panicProgress = currentStep / totalSteps;
      notifyListeners();

      if (currentStep >= totalSteps) {
        timer.cancel();
        _panicProgress = 1.0;
        notifyListeners();
        _performPanicCall();
      }
    });
  }

  Future<void> _performPanicCall() async {
    try {
      await _phoneCallService.callPhoneNumber(_caregiverPhoneNumber);
    } catch (error) {
      _errorMessage = 'Erro ao iniciar chamada: $error';
    } finally {
      _isPanicInProgress = false;
      _panicProgress = 0.0;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
  }
}
