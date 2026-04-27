import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../flashlight/presentation/controllers/flashlight_controller.dart';
import '../../../video_loop/domain/models/video_loop_settings.dart';
//import '../../../settings/domain/models/alert_settings.dart';
//import '../../../settings/domain/models/caregiver.dart';
//import '../../../settings/domain/models/user_feature_settings.dart';
import '../../../video_loop/presentation/controllers/video_loop_controller.dart'; //temp

class HomeController extends ChangeNotifier {
  HomeController({
    required StorageService storageService,
    required PhoneCallService phoneCallService,
    required this.flashlightController,
    required this.videoLoopController, // temp
  }) : _storageService = storageService,
       _phoneCallService = phoneCallService;

  final StorageService _storageService;
  final PhoneCallService _phoneCallService;
  final FlashlightController flashlightController;
  final VideoLoopController videoLoopController; // temp

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isFallDetectionActive = true;
  bool get isFallDetectionActive => _isFallDetectionActive;

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
    final caregiver = await _storageService.loadCaregiver();
    final userFeatureSettings = await _storageService.loadUserFeatureSettings();
    final alertSettings = await _storageService.loadAlertSettings();

    _caregiverName = caregiver.name;
    _caregiverPhoneNumber = caregiver.phoneNumber;
    _showFallDetectionButton = userFeatureSettings.showFallDetectionButton;
    _showPanicButton = userFeatureSettings.showPanicButton;

    await flashlightController.initialize();
    await flashlightController.setDarknessThresholdLux(
      userFeatureSettings.flashlightDarknessThresholdLux,
    );
    await flashlightController.setAutoModeEnabled(
      userFeatureSettings.enableAutomaticFlashlightMode,
    );

    final videoSettings = VideoLoopSettings(
      enabled: alertSettings.recordAndSendVideo,
      bufferSeconds: alertSettings.circularRecordingSeconds,
      withAudio: false,
      quality: VideoLoopQuality.p480,
      fps: 15,
      segmentSeconds: 5,
    );

    final isVideoRecordingEnabled = alertSettings.recordAndSendVideo;

    if (isVideoRecordingEnabled) {
      await videoLoopController.initialize(videoSettings);
      await videoLoopController.startIfEnabled();
    } else {
      await videoLoopController.disableAndClear();
    }

    await flashlightController.setBlockedByVideoRecording(
      isVideoRecordingEnabled,
    );

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

  // temp
  Future<void> simulateFallAlert() async {
    final evidence = await videoLoopController
        .preserveEvidenceForSimulatedFall();

    if (evidence == null) {
      _errorMessage = 'Sem evidência de vídeo disponível.';
      notifyListeners();
      return;
    }

    _errorMessage =
        'Alerta simulado: vídeo preservado em ${evidence.folderPath}';

    debugPrint('Evidence folder: ${evidence.folderPath}');
    notifyListeners();
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
  }
}
