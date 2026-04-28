import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../flashlight/presentation/controllers/flashlight_controller.dart';
import '../../../video_loop/domain/models/video_loop_settings.dart';
import '../../../video_loop/presentation/controllers/video_loop_controller.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required StorageService storageService,
    required PhoneCallService phoneCallService,
    required this.flashlightController,
    required this.videoLoopController,
    required this.caregiverDriveController,
  }) : _storageService = storageService,
       _phoneCallService = phoneCallService;

  final StorageService _storageService;
  final PhoneCallService _phoneCallService;
  final FlashlightController flashlightController;
  final VideoLoopController videoLoopController;
  final CaregiverDriveController caregiverDriveController;

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

    final totalSteps =
        totalDuration.inMilliseconds ~/ stepDuration.inMilliseconds;

    var currentStep = 0;

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

  Future<void> simulateFallAlert() async {
    try {
      final alertSettings = await _storageService.loadAlertSettings();

      if (!alertSettings.recordAndSendVideo) {
        _errorMessage =
            'Alerta simulado sem vídeo. O upload para Drive só acontece quando a gravação de vídeo está ativa.';
        notifyListeners();
        return;
      }

      final evidence = await videoLoopController
          .preserveEvidenceForSimulatedFall();

      if (evidence == null) {
        _errorMessage = 'Sem evidência de vídeo disponível.';
        notifyListeners();
        return;
      }

      if (!caregiverDriveController.session.hasLinkedAccount) {
        _errorMessage =
            'Vídeo preservado, mas o Google Drive do cuidador não está ligado.';
        debugPrint('Evidence folder: ${evidence.folderPath}');
        notifyListeners();

        await videoLoopController.restartLoopIfEnabled();
        return;
      }

      final uploadResult = await caregiverDriveController.uploadEvidenceFolder(
        evidenceFolderPath: evidence.folderPath,
        alertTime: evidence.alertTime,
      );

      if (uploadResult == null) {
        _errorMessage =
            'Vídeo preservado, mas falhou o upload para Google Drive.';
        debugPrint('Evidence folder: ${evidence.folderPath}');
        notifyListeners();

        await videoLoopController.restartLoopIfEnabled();
        return;
      }

      _errorMessage = 'Alerta simulado: vídeo enviado para Google Drive.';
      debugPrint('Evidence folder: ${evidence.folderPath}');
      notifyListeners();

      await videoLoopController.restartLoopIfEnabled();
    } catch (error) {
      _errorMessage = 'Falha ao processar alerta simulado: $error';
      notifyListeners();

      await videoLoopController.restartLoopIfEnabled();
    }
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
  }
}
