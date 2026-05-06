import 'package:flutter/material.dart';

import '../../../../core/services/flashlight_service.dart';
import '../../../../core/services/light_sensor_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/sms_alert_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/video_consolidation_service.dart';
import '../../../../core/services/video_evidence_cleanup_service.dart';
import '../../../../core/services/video_storage_service.dart';
import '../../../../core/services/voice_alert_service.dart';
import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../fall_detection/presentation/controllers/fall_detection_controller.dart';
import '../../../fall_detection/services/fall_detection_service.dart';
import '../../../flashlight/presentation/controllers/flashlight_controller.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';
import '../../../settings/presentation/pages/settings_host_page.dart';
import '../../../video_loop/presentation/controllers/video_loop_controller.dart';
import '../../../video_loop/services/circular_video_recorder.dart';
import '../controllers/home_controller.dart';
import '../widgets/fall_detection_card.dart';
import '../widgets/flashlight_card.dart';
import '../widgets/panic_card.dart';

class HomePage extends StatefulWidget {
  final CaregiverDriveController caregiverDriveController;

  const HomePage({super.key, required this.caregiverDriveController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final StorageService _storageService;
  late final FlashlightController _flashlightController;
  late final LightSensorController _lightSensorController;
  late final FallDetectionController _fallDetectionController;
  late final VideoStorageService _videoStorageService;
  late final VideoLoopController _videoLoopController;
  late final VideoConsolidationService _videoConsolidationService;
  late final VideoEvidenceCleanupService _videoEvidenceCleanupService;
  late final SmsAlertService _smsAlertService;
  late final LocationService _locationService;
  late final HomeController _controller;
  late final VoiceAlertService _voiceAlertService;

  @override
  void initState() {
    super.initState();

    _storageService = StorageService();
    
    _voiceAlertService = VoiceAlertService();

    _flashlightController = FlashlightController(
      flashlightService: FlashlightService(),
      voiceAlertService: _voiceAlertService,
    );

    _lightSensorController = LightSensorController(
      lightSensorService: LightSensorService(),
    );

    _fallDetectionController = FallDetectionController(
      fallDetectionService: FallDetectionService(),
    );

    _videoStorageService = VideoStorageService();

    _videoLoopController = VideoLoopController(
      recorder: CircularVideoRecorder(storageService: _videoStorageService),
      storageService: _videoStorageService,
    );

    _videoConsolidationService = VideoConsolidationService();
    _videoEvidenceCleanupService = VideoEvidenceCleanupService();
    _smsAlertService = SmsAlertServiceImpl();
    _locationService = LocationService();

    _controller = HomeController(
      storageService: _storageService,
      phoneCallService: PhoneCallService(),
      flashlightController: _flashlightController,
      videoLoopController: _videoLoopController,
      caregiverDriveController: widget.caregiverDriveController,
      videoConsolidationService: _videoConsolidationService,
      videoEvidenceCleanupService: _videoEvidenceCleanupService,
      smsAlertService: _smsAlertService,
      locationService: _locationService,
      voiceAlertService: _voiceAlertService,
    );

    _controller.addListener(_onControllerChanged);
    _flashlightController.addListener(_onFlashlightChanged);
    _lightSensorController.addListener(_onLightSensorChanged);
    _fallDetectionController.addListener(_onFallDetectionChanged);
    _videoLoopController.addListener(_onVideoLoopChanged);
    widget.caregiverDriveController.addListener(_onDriveChanged);

    _initializePage();
  }

  Future<void> _initializePage() async {
    await widget.caregiverDriveController.initialize();
    await _controller.loadHomeSettings();

    await _lightSensorController.startListening(
      onLuxChanged: (lux) {
        _flashlightController.updateLux(lux);
      },
    );

    final userFeatureSettings = await _storageService.loadUserFeatureSettings();

    if (userFeatureSettings.showSimulateFallButton) {
      if (_fallDetectionController.isEnabled) {
        await _fallDetectionController.disable();
      }

      await _storageService.saveUserFeatureSettings(
        userFeatureSettings.copyWith(fallDetectionEnabled: false),
      );
    } else if (userFeatureSettings.fallDetectionEnabled) {
      await _fallDetectionController.enable(
        onFallDetected: _controller.simulateFallAlert,
      );
    }
  }

  Future<void> _toggleFallDetection() async {
    final currentSettings = await _storageService.loadUserFeatureSettings();

    if (_fallDetectionController.isEnabled) {
      await _fallDetectionController.disable();

      if (!_fallDetectionController.isEnabled) {
        await _storageService.saveUserFeatureSettings(
          currentSettings.copyWith(fallDetectionEnabled: false),
        );
      }
    } else {
      await _fallDetectionController.enable(
        onFallDetected: _controller.simulateFallAlert,
      );

      if (_fallDetectionController.isEnabled) {
        await _storageService.saveUserFeatureSettings(
          currentSettings.copyWith(fallDetectionEnabled: true),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsHostPage(
          lightSensorController: _lightSensorController,
          caregiverDriveController: widget.caregiverDriveController,
        ),
      ),
    );

    if (result == true) {
      await _controller.loadHomeSettings();

      final userFeatureSettings = await _storageService
          .loadUserFeatureSettings();

      if (userFeatureSettings.showSimulateFallButton) {
        if (_fallDetectionController.isEnabled) {
          await _fallDetectionController.disable();
        }

        await _storageService.saveUserFeatureSettings(
          userFeatureSettings.copyWith(fallDetectionEnabled: false),
        );
      } else if (userFeatureSettings.fallDetectionEnabled &&
          !_fallDetectionController.isEnabled) {
        await _fallDetectionController.enable(
          onFallDetected: _controller.simulateFallAlert,
        );
      } else if (!userFeatureSettings.fallDetectionEnabled &&
          _fallDetectionController.isEnabled) {
        await _fallDetectionController.disable();
      }

      final lux = _lightSensorController.currentLux;
      if (lux != null) {
        await _flashlightController.updateLux(lux);
      }
    }
  }

  void _onControllerChanged() {
    final errorMessage = _controller.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _controller.clearError();
    }
  }

  void _onFlashlightChanged() {
    final errorMessage = _flashlightController.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _flashlightController.clearError();
    }
  }

  void _onLightSensorChanged() {
    final errorMessage = _lightSensorController.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _lightSensorController.clearError();
    }
  }

  void _onFallDetectionChanged() {
    final errorMessage = _fallDetectionController.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _fallDetectionController.clearError();
    }
  }

  void _onVideoLoopChanged() {
    final errorMessage = _videoLoopController.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      _videoLoopController.clearError();
    }
  }

  void _onDriveChanged() {
    final errorMessage = widget.caregiverDriveController.errorMessage;

    if (errorMessage != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMessage)));
      widget.caregiverDriveController.clearError();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _flashlightController.removeListener(_onFlashlightChanged);
    _lightSensorController.removeListener(_onLightSensorChanged);
    _fallDetectionController.removeListener(_onFallDetectionChanged);
    _videoLoopController.removeListener(_onVideoLoopChanged);
    widget.caregiverDriveController.removeListener(_onDriveChanged);

    _controller.dispose();
    _flashlightController.dispose();
    _lightSensorController.dispose();
    _fallDetectionController.disposeAsync();
    _fallDetectionController.dispose();
    _videoLoopController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller,
        _flashlightController,
        _lightSensorController,
        _fallDetectionController,
        _videoLoopController,
        widget.caregiverDriveController,
      ]),
      builder: (context, _) {
        if (_controller.isLoading ||
            widget.caregiverDriveController.isLoading) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Image.asset(
              'assets/images/logo.png',
              height: 32,
              fit: BoxFit.contain,
            ),
            actions: [
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(Icons.settings),
              ),
            ],
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_controller.showFallDetectionButton) ...[
                  FallDetectionCard(
                    isActive: _fallDetectionController.isEnabled,
                    isDisabled: _controller.showSimulateFallButton,
                    disabledReason: _controller.showSimulateFallButton
                        ? 'Desativada enquanto o botão de simulação estiver visível'
                        : null,
                    onTap: _toggleFallDetection,
                  ),
                ],
                if (_controller.showSimulateFallButton) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _controller.simulateFallAlert,
                      icon: const Icon(Icons.warning_amber_rounded),
                      label: const Text('Simular queda (teste)'),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                FlashlightCard(
                  isActive: _flashlightController.isOn,
                  isAvailable: _flashlightController.isAvailable,
                  autoModeEnabled: _flashlightController.autoModeEnabled,
                  manualOverrideActive:
                      _flashlightController.manualOverrideActive,
                  blockedByVideoRecording:
                      _flashlightController.blockedByVideoRecording,
                  onTap: _flashlightController.toggleManual,
                ),
                if (_controller.showPanicButton) ...[
                  const SizedBox(height: 24),
                  PanicCard(
                    caregiverName: _controller.caregiverName,
                    isInProgress: _controller.isPanicInProgress,
                    progress: _controller.panicProgress,
                    onTap: _controller.startPanicFlow,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
