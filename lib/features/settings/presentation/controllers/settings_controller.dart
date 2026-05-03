import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../domain/models/alert_settings.dart';
import '../../domain/models/caregiver.dart';
import '../../domain/models/user_feature_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({required StorageService storageService})
    : _storageService = storageService;

  final StorageService _storageService;

  final formKey = GlobalKey<FormState>();

  late final TextEditingController caregiverNameController;
  late final TextEditingController caregiverEmailController;
  late final TextEditingController caregiverPhoneController;
  late final TextEditingController pinController;

  double _flashlightDarknessThresholdLux = 20.0;
  double get flashlightDarknessThresholdLux => _flashlightDarknessThresholdLux;

  int? _currentLux;
  int? get currentLux => _currentLux;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _makePhoneCall = true;
  bool get makePhoneCall => _makePhoneCall;

  bool _sendSms = false;
  bool get sendSms => _sendSms;

  bool _sendGps = false;
  bool get sendGps => _sendGps;

  bool _recordAndSendVideo = false;
  bool get recordAndSendVideo => _recordAndSendVideo;

  int _circularRecordingSeconds = 60;
  int get circularRecordingSeconds => _circularRecordingSeconds;

  bool _showFallDetectionButton = true;
  bool get showFallDetectionButton => _showFallDetectionButton;

  bool _showPanicButton = true;
  bool get showPanicButton => _showPanicButton;

  bool _enableAutomaticFlashlightMode = false;
  bool get enableAutomaticFlashlightMode => _enableAutomaticFlashlightMode;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    caregiverNameController = TextEditingController();
    caregiverEmailController = TextEditingController();
    caregiverPhoneController = TextEditingController();
    pinController = TextEditingController();

    await loadSettings();
  }

  Future<void> loadSettings() async {
    final caregiver = await _storageService.loadCaregiver();
    final alertSettings = await _storageService.loadAlertSettings();
    final userFeatureSettings = await _storageService.loadUserFeatureSettings();

    caregiverNameController.text = caregiver.name;
    caregiverEmailController.text = caregiver.email;
    caregiverPhoneController.text = caregiver.phoneNumber;
    pinController.text = caregiver.pin;

    _makePhoneCall = alertSettings.makePhoneCall;
    _sendSms = alertSettings.sendSms;
    _sendGps = alertSettings.sendGps;
    _recordAndSendVideo = alertSettings.recordAndSendVideo;
    _circularRecordingSeconds = alertSettings.circularRecordingSeconds;

    _showFallDetectionButton = userFeatureSettings.showFallDetectionButton;
    _showPanicButton = userFeatureSettings.showPanicButton;
    _enableAutomaticFlashlightMode =
        userFeatureSettings.enableAutomaticFlashlightMode;
    _flashlightDarknessThresholdLux =
        userFeatureSettings.flashlightDarknessThresholdLux;

    _isLoading = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
  }

  void setMakePhoneCall(bool value) {
    _makePhoneCall = value;
    notifyListeners();
  }

  void setSendSms(bool value) {
    final bool smsIsForced = _sendGps || _recordAndSendVideo;

    if (smsIsForced) {
      _sendSms = true;
    } else {
      _sendSms = value;
    }

    notifyListeners();
  }

  bool get isSendSmsForced => _sendGps || _recordAndSendVideo;

  void setSendGps(bool value) {
    _sendGps = value;

    if (_sendGps) {
      _sendSms = true;
    }

    notifyListeners();
  }

  void setRecordAndSendVideo(bool value) {
    _recordAndSendVideo = value;

    if (_recordAndSendVideo) {
      _sendSms = true;
    }

    notifyListeners();
  }

  void setCircularRecordingSeconds(int value) {
    _circularRecordingSeconds = value;
    notifyListeners();
  }

  void setShowFallDetectionButton(bool value) {
    _showFallDetectionButton = value;
    notifyListeners();
  }

  void setShowPanicButton(bool value) {
    _showPanicButton = value;
    notifyListeners();
  }

  void setEnableAutomaticFlashlightMode(bool value) {
    _enableAutomaticFlashlightMode = value;
    notifyListeners();
  }

  void setFlashlightDarknessThresholdLux(double value) {
    _flashlightDarknessThresholdLux = value;
    notifyListeners();
  }

  void setCurrentLux(int? value) {
    _currentLux = value;
    notifyListeners();
  }

  Future<bool> saveSettings() async {
    if (_isSaving) return false;

    final isValid = formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _errorMessage = 'Corrige os campos antes de sair.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    notifyListeners();

    final caregiver = Caregiver(
      name: caregiverNameController.text.trim(),
      email: caregiverEmailController.text.trim(),
      phoneNumber: caregiverPhoneController.text.trim(),
      pin: pinController.text.trim(),
    );

    final alertSettings = AlertSettings(
      makePhoneCall: _makePhoneCall,
      sendSms: _sendSms,
      sendGps: _sendGps,
      recordAndSendVideo: _recordAndSendVideo,
      circularRecordingSeconds: _circularRecordingSeconds,
    );

    final userFeatureSettings = UserFeatureSettings(
      showFallDetectionButton: _showFallDetectionButton,
      showPanicButton: _showPanicButton,
      enableAutomaticFlashlightMode: _enableAutomaticFlashlightMode,
      flashlightDarknessThresholdLux: _flashlightDarknessThresholdLux,
    );

    try {
      await _storageService.saveCaregiver(caregiver);
      await _storageService.saveAlertSettings(alertSettings);
      await _storageService.saveUserFeatureSettings(userFeatureSettings);
      return true;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    caregiverNameController.dispose();
    caregiverEmailController.dispose();
    caregiverPhoneController.dispose();
    pinController.dispose();
    super.dispose();
  }
}
