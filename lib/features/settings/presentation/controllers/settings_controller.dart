import 'package:flutter/material.dart';

import '../../../../core/services/storage_service.dart';
import '../../domain/models/alert_settings.dart';
import '../../domain/models/caregiver.dart';
import '../../domain/models/user_feature_settings.dart';

import '../../../../core/logging/app_logger.dart';

import '../../../../core/constants/settings_defaults.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required StorageService storageService,
    required AppLogger logger,
  }): 
  _storageService = storageService,
  _logger = logger;

  final StorageService _storageService;

  final formKey = GlobalKey<FormState>();

  late final TextEditingController caregiverNameController;
  late final TextEditingController caregiverEmailController;
  late final TextEditingController caregiverPhoneController;
  late final TextEditingController pinController;
  final AppLogger _logger;

  double _flashlightDarknessThresholdLux = 5.0;
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

  int _circularRecordingSeconds = 30;
  int get circularRecordingSeconds => _circularRecordingSeconds;

  bool _showFallDetectionButton = true;
  bool get showFallDetectionButton => _showFallDetectionButton;

  bool _showPanicButton = true;
  bool get showPanicButton => _showPanicButton;

  bool _enableAutomaticFlashlightMode = false;
  bool get enableAutomaticFlashlightMode => _enableAutomaticFlashlightMode;

  bool _showSimulateFallButton = false;
  bool get showSimulateFallButton => _showSimulateFallButton;  

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    caregiverNameController = TextEditingController();
    caregiverEmailController = TextEditingController();
    caregiverPhoneController = TextEditingController();
    pinController = TextEditingController();

    await loadSettings();
    await _logger.logSystemEvent(
      module: 'settings_controller',
      action: 'settings_loaded',
      details:
          'showFallDetectionButton=$_showFallDetectionButton;'
          'showPanicButton=$_showPanicButton;'
          'showSimulateFallButton=$_showSimulateFallButton;'
          'sendSms=$_sendSms;'
          'sendGps=$_sendGps;'
          'recordAndSendVideo=$_recordAndSendVideo;'
          'makePhoneCall=$_makePhoneCall',
    );
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
    _showSimulateFallButton = userFeatureSettings.showSimulateFallButton;
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
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_make_phone_call',
      details: 'value=$value',
    );
  }

  void setSendSms(bool value) {
    final bool smsIsForced = isSendSmsForced;

    if ((smsIsForced || value) && caregiverPhoneController.text == SettingsDefaults.caregiverPhone){
      
      _errorMessage='Deve mudar o número de telefone para enviar SMS';
      _sendSms = false;

    } else {

    if (smsIsForced) {
      _sendSms = true;
    } else {
      _sendSms = value;
    }
    }


    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_send_sms',
      details: 'value=$_sendSms;forced=$smsIsForced',
    );
    

  }

  bool get isSendSmsForced => _sendGps || _recordAndSendVideo;

  void setSendGps(bool value) {
    _sendGps = value;

    if (_sendGps) {
      setSendSms(true);
      _sendGps = _sendSms;
      _errorMessage = _sendSms ? null: 'SMS deve estar ativado para enviar localização GPS';
    } 

    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_send_gps',
      details: 'sendGps=$_sendGps;sendSms=$_sendSms',
    );
    

  }

  void setRecordAndSendVideo(bool value) {
    _recordAndSendVideo = value;

    if (_recordAndSendVideo) {
      setSendSms(true);
      _recordAndSendVideo = _sendSms;
      _errorMessage = _sendSms ? null : 'SMS deve estar ativado para enviar link de vídeo';
    } 

    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_record_and_send_video',
      details: 'recordAndSendVideo=$_recordAndSendVideo;sendSms=$_sendSms',
    );
  }

  void setCircularRecordingSeconds(int value) {
    _circularRecordingSeconds = value;
    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'change_circular_recording_seconds',
      details: 'value=$_circularRecordingSeconds',
    );
  }

  void setShowFallDetectionButton(bool value) {
    _showFallDetectionButton = value;
    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_show_fall_detection_button',
      details: 'value=$value',
    );
  }

  void setShowPanicButton(bool value) {
    _showPanicButton = value;
    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_show_panic_button',
      details: 'value=$value',
    );
  }

  void setShowSimulateFallButton(bool value) {
    _showSimulateFallButton = value;
    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_show_simulate_fall_button',
      details: 'value=$value',
    );
  }

  void setEnableAutomaticFlashlightMode(bool value) {
    _enableAutomaticFlashlightMode = value;
    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'toggle_automatic_flashlight_mode',
      details: 'value=$value',
    );
  }

  void setFlashlightDarknessThresholdLux(double value) {
    _flashlightDarknessThresholdLux = value;
    notifyListeners();
    _logger.logUserAction(
      module: 'settings_controller',
      action: 'change_flashlight_darkness_threshold_lux',
      details: 'value=$_flashlightDarknessThresholdLux',
    );
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
      await _logger.logError(
        module: 'settings_controller',
        action: 'save_settings_validation_failed',
      );
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

    final currentUserFeatureSettings = await _storageService
        .loadUserFeatureSettings();

    final userFeatureSettings = UserFeatureSettings(
      showFallDetectionButton: _showFallDetectionButton,
      showPanicButton: _showPanicButton,
      enableAutomaticFlashlightMode: _enableAutomaticFlashlightMode,
      flashlightDarknessThresholdLux: _flashlightDarknessThresholdLux,
      showSimulateFallButton: _showSimulateFallButton,
      fallDetectionEnabled: currentUserFeatureSettings.fallDetectionEnabled,
    );

    try {
      await _storageService.saveCaregiver(caregiver);
      await _storageService.saveAlertSettings(alertSettings);
      await _storageService.saveUserFeatureSettings(userFeatureSettings);
      await _logger.logSystemEvent(
        module: 'settings_controller',
        action: 'settings_saved',
        details:
            'makePhoneCall=$_makePhoneCall;'
            'sendSms=$_sendSms;'
            'sendGps=$_sendGps;'
            'recordAndSendVideo=$_recordAndSendVideo;'
            'circularRecordingSeconds=$_circularRecordingSeconds;'
            'showFallDetectionButton=$_showFallDetectionButton;'
            'showPanicButton=$_showPanicButton;'
            'showSimulateFallButton=$_showSimulateFallButton;'
            'automaticFlashlight=$_enableAutomaticFlashlightMode;'
            'flashlightLux=$_flashlightDarknessThresholdLux',
      );
      return true;
    } catch (error) {
    _errorMessage = 'Não foi possível guardar as configurações.';
    _isSaving = false;
    notifyListeners();

    await _logger.logError(
      module: 'settings_controller',
      action: 'settings_save_failed',
      details: error.toString(),
    );

    return false;
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
