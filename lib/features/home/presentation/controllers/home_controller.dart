import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/video_consolidation_service.dart';
import '../../../../core/services/video_evidence_cleanup_service.dart';
import '../../../../core/services/sms_alert_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/voice_alert_service.dart';

import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../flashlight/presentation/controllers/flashlight_controller.dart';
import '../../../video_loop/domain/models/video_loop_settings.dart';
import '../../../video_loop/presentation/controllers/video_loop_controller.dart';

import '../../../../core/logging/app_logger.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    required StorageService storageService,
    required PhoneCallService phoneCallService,
    required this.flashlightController,
    required this.videoLoopController,
    required this.caregiverDriveController,
    required VideoConsolidationService videoConsolidationService,
    required VideoEvidenceCleanupService videoEvidenceCleanupService,
    required SmsAlertService smsAlertService,
    required LocationService locationService,
    required VoiceAlertService voiceAlertService,
    required AppLogger logger,
  }) : _storageService = storageService,
       _phoneCallService = phoneCallService,
       _videoConsolidationService = videoConsolidationService,
       _videoEvidenceCleanupService = videoEvidenceCleanupService,
       _smsAlertService = smsAlertService,
       _locationService = locationService,
       _voiceAlertService = voiceAlertService,
       _logger = logger;

  final StorageService _storageService;
  final PhoneCallService _phoneCallService;
  final FlashlightController flashlightController;
  final VideoLoopController videoLoopController;
  final CaregiverDriveController caregiverDriveController;
  final VideoConsolidationService _videoConsolidationService;
  final VideoEvidenceCleanupService _videoEvidenceCleanupService;
  final SmsAlertService _smsAlertService;
  final LocationService _locationService;
  final VoiceAlertService _voiceAlertService;
  final AppLogger _logger;

  static const bool deleteLocalEvidenceAfterSuccessfulUpload = true;

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

  bool _showSimulateFallButton = false;
  bool get showSimulateFallButton => _showSimulateFallButton;

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
    _showSimulateFallButton = userFeatureSettings.showSimulateFallButton;
    
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
    await _logger.logSystemEvent(
      module: 'home_controller',
      action: 'home_settings_loaded',
      details:
          'showFallDetectionButton=$_showFallDetectionButton;'
          'showPanicButton=$_showPanicButton;'
          'showSimulateFallButton=$_showSimulateFallButton;'
          'recordAndSendVideo=${alertSettings.recordAndSendVideo};'
          'sendSms=${alertSettings.sendSms};'
          'sendGps=${alertSettings.sendGps};'
          'makePhoneCall=${alertSettings.makePhoneCall}',
    );
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

      _logger.logError(
        module: 'home_controller',
        action: 'panic_flow_blocked',
        details: 'reason=missing_caregiver_phone',
      );
      return;
    }

    _logger.logUserAction(module: 'home_controller', action: 'panic_button_pressed');

    _isPanicInProgress = true;
    _panicProgress = 0.0;
    _errorMessage = null;
    notifyListeners();

    _announcePanicCall();

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

        _logger.logSystemEvent(
          module: 'home_controller',
          action: 'panic_countdown_completed',
        );

        _performPanicCall();
      }
    });
  }

  Future<void> _performPanicCall() async {
    try {
      await _phoneCallService.callPhoneNumber(_caregiverPhoneNumber);

      await _logger.logSystemEvent(
        module: 'home_controller',
        action: 'panic_call_started',
      );
    } catch (error) {
      _errorMessage = 'Erro ao iniciar chamada: $error';

      await _logger.logError(
        module: 'home_controller',
        action: 'panic_call_failed',
        details: error.toString(),
      );
    } finally {
      _isPanicInProgress = false;
      _panicProgress = 0.0;
      notifyListeners();
    }
  }

  Future<void> _announcePanicCall() async {
    try {
      await _voiceAlertService.speakCallingCaregiver();
    } catch (_) {
      // Ignora falha de TTS para não bloquear o fluxo de pânico.
    }
  }

  String _formatAlertTimestamp(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');

    return '${dateTime.year}/${twoDigits(dateTime.month)}/${twoDigits(dateTime.day)} '
        '${twoDigits(dateTime.hour)}:${twoDigits(dateTime.minute)}:${twoDigits(dateTime.second)}';
  }

  String _buildAlertMessage(String message) {
    final prefix = _showSimulateFallButton ? 'Alerta de queda simulado' : 'Alerta de queda';
    return '$prefix: $message';
  }

  Future<void> simulateFallAlert() async {
    bool shouldProcessVideo = false;
    bool shouldMakePhoneCall = false;

    try {
      final alertSettings = await _storageService.loadAlertSettings();
      final DateTime alertTime = DateTime.now();

      final bool shouldSendSms =
          alertSettings.sendSms ||
          alertSettings.sendGps ||
          alertSettings.recordAndSendVideo;

      shouldProcessVideo = alertSettings.recordAndSendVideo;
      shouldMakePhoneCall = alertSettings.makePhoneCall;

      await _logger.logUserAction(
        module: 'home_controller',
        action: _showSimulateFallButton
            ? 'simulate_fall_button_pressed'
            : 'fall_alert_triggered',
        details:
            'sendSms=$shouldSendSms;'
            'sendGps=${alertSettings.sendGps};'
            'recordAndSendVideo=${alertSettings.recordAndSendVideo};'
            'makePhoneCall=${alertSettings.makePhoneCall}',
      );

      String smsMessage = 'Alerta de queda ${_formatAlertTimestamp(alertTime)}';

      String? evidenceFolderPath;
      bool videoUploadedSuccessfully = false;
      bool smsSentSuccessfully = false;
      bool callStartedSuccessfully = false;

      if (alertSettings.sendGps) {
        try {
          final location = await _locationService.getCurrentLocation();
          smsMessage += '\nLocalização: ${location.googleMapsLink}';

          await _logger.logSystemEvent(
            module: 'home_controller',
            action: 'gps_obtained',
          );
        } catch (error) {
          smsMessage += '\nLocalização: indisponível';

          await _logger.logError(
            module: 'home_controller',
            action: 'gps_failed',
            details: error.toString(),
          );
        }
      }

      if (shouldProcessVideo) {
        try {
          final evidence = await videoLoopController
              .preserveEvidenceForSimulatedFall();

          if (evidence != null) {
            evidenceFolderPath = evidence.folderPath;

            await _logger.logSystemEvent(
              module: 'home_controller',
              action: 'video_evidence_preserved',
              details: 'folder=${evidence.folderPath}',
            );

            await _videoConsolidationService.consolidateEvidenceFolder(
              evidence.folderPath,
            );

            await _logger.logSystemEvent(
              module: 'home_controller',
              action: 'video_consolidated',
              details: 'folder=${evidence.folderPath}',
            );

            if (caregiverDriveController.session.hasLinkedAccount) {
              final uploadResult = await caregiverDriveController
                  .uploadEvidenceFolder(
                    evidenceFolderPath: evidence.folderPath,
                    alertTime: evidence.alertTime,
                  );

              if (uploadResult != null &&
                  uploadResult.alertVideoWebViewLink != null &&
                  uploadResult.alertVideoWebViewLink!.trim().isNotEmpty) {
                videoUploadedSuccessfully = true;
                smsMessage += '\nVídeo: ${uploadResult.alertVideoWebViewLink}';

                await _logger.logSystemEvent(
                  module: 'home_controller',
                  action: 'video_upload_success',
                  details:
                      'fileId=${uploadResult.alertVideoFileId ?? ''};'
                      'folderId=${uploadResult.alertFolderId}',
                );
              } else {
                _errorMessage =
                    'Vídeo preservado e consolidado, mas falhou o upload para Google Drive.';
                notifyListeners();

                await _logger.logError(
                  module: 'home_controller',
                  action: 'video_upload_failed',
                );
              }
            } else {
              _errorMessage =
                  'Vídeo preservado e consolidado, mas o Google Drive do cuidador não está ligado.';
              notifyListeners();

              await _logger.logError(
                module: 'home_controller',
                action: 'drive_not_linked',
              );
            }
          } else {
            _errorMessage = 'Sem evidência de vídeo disponível.';
            notifyListeners();

            await _logger.logError(
              module: 'home_controller',
              action: 'video_evidence_missing',
            );
          }
        } catch (error) {
          _errorMessage = 'Falha no processamento do vídeo do alerta: $error';
          notifyListeners();

          await _logger.logError(
            module: 'home_controller',
            action: 'video_processing_failed',
            details: error.toString(),
          );
        }
      }

      if (shouldSendSms) {
        try {
          await _smsAlertService.sendFallAlertSms(
            phoneNumber: _caregiverPhoneNumber,
            message: smsMessage,
          );
          smsSentSuccessfully = true;

          await _logger.logSystemEvent(
            module: 'home_controller',
            action: 'sms_sent',
            details:
                'hasGps=${alertSettings.sendGps};'
                'hasVideoLink=$videoUploadedSuccessfully',
          );
        } catch (error) {
          await _logger.logError(
            module: 'home_controller',
            action: 'sms_failed',
            details: error.toString(),
          );
        }
      }

      if (shouldMakePhoneCall) {
        try {
          await _phoneCallService.callPhoneNumber(_caregiverPhoneNumber);
          callStartedSuccessfully = true;

          await _logger.logSystemEvent(
            module: 'home_controller',
            action: 'fall_alert_call_started',
          );
        } catch (error) {
          _errorMessage = 'Falha ao iniciar chamada do alerta: $error';
          notifyListeners();

          await _logger.logError(
            module: 'home_controller',
            action: 'fall_alert_call_failed',
            details: error.toString(),
          );
        }
      }

      if (deleteLocalEvidenceAfterSuccessfulUpload &&
          videoUploadedSuccessfully &&
          evidenceFolderPath != null) {
        await _videoEvidenceCleanupService.deleteEvidenceFolder(
          evidenceFolderPath,
        );

        await _logger.logSystemEvent(
          module: 'home_controller',
          action: 'local_evidence_deleted',
          details: 'folder=$evidenceFolderPath',
        );
      }

      if (!shouldMakePhoneCall &&
          (videoUploadedSuccessfully || smsSentSuccessfully)) {
        await _voiceAlertService.speakAlertSentToCaregiver();
      }

      final parts = <String>[];

      if (videoUploadedSuccessfully) {
        parts.add('vídeo enviado para Google Drive');
      }

      if (smsSentSuccessfully) {
        parts.add('SMS enviado');
      }

      if (callStartedSuccessfully) {
        parts.add('chamada iniciada');
      }

      if (parts.isEmpty) {
        _errorMessage = 'Não foi possível executar nenhuma ação do alerta.';

        await _logger.logError(
          module: 'home_controller',
          action: 'alert_no_action_executed',
        );
      } else {
        _errorMessage = _buildAlertMessage(parts.join(', '));

        await _logger.logSystemEvent(
          module: 'home_controller',
          action: 'alert_completed',
          details: parts.join(';'),
        );
      }

      debugPrint('Evidence folder: $evidenceFolderPath');
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Falha ao processar alerta: $error';
      notifyListeners();

      await _logger.logError(
        module: 'home_controller',
        action: 'alert_processing_failed',
        details: error.toString(),
      );
    } finally {
      if (shouldProcessVideo) {
        await videoLoopController.restartLoopIfEnabled();

        await _logger.logSystemEvent(
          module: 'home_controller',
          action: 'video_loop_restarted',
        );
      }
    }
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
  }
}
