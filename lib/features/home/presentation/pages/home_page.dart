import 'package:flutter/material.dart';

import '../../../../core/services/flashlight_service.dart';
import '../../../../core/services/light_sensor_service.dart';
import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/video_storage_service.dart';
import '../../../drive_backup/presentation/controllers/caregiver_drive_controller.dart';
import '../../../flashlight/presentation/controllers/flashlight_controller.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';
import '../../../settings/presentation/pages/settings_host_page.dart';
import '../../../video_loop/presentation/controllers/video_loop_controller.dart';
import '../../../video_loop/services/circular_video_recorder.dart';
import '../../../../core/services/video_consolidation_service.dart';
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
  late final FlashlightController _flashlightController;
  late final LightSensorController _lightSensorController;
  late final VideoStorageService _videoStorageService;
  late final VideoLoopController _videoLoopController;
  late final HomeController _controller;
  late final VideoConsolidationService _videoConsolidationService;

  @override
  void initState() {
    super.initState();

    _flashlightController = FlashlightController(
      flashlightService: FlashlightService(),
    );

    _lightSensorController = LightSensorController(
      lightSensorService: LightSensorService(),
    );

    _videoStorageService = VideoStorageService();

    _videoLoopController = VideoLoopController(
      recorder: CircularVideoRecorder(storageService: _videoStorageService),
      storageService: _videoStorageService,
    );

    _videoConsolidationService = VideoConsolidationService();

    _controller = HomeController(
      storageService: StorageService(),
      phoneCallService: PhoneCallService(),
      flashlightController: _flashlightController,
      videoLoopController: _videoLoopController,
      caregiverDriveController: widget.caregiverDriveController,
      videoConsolidationService: _videoConsolidationService,
    );

    _controller.addListener(_onControllerChanged);
    _flashlightController.addListener(_onFlashlightChanged);
    _lightSensorController.addListener(_onLightSensorChanged);
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
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _flashlightController.removeListener(_onFlashlightChanged);
    _lightSensorController.removeListener(_onLightSensorChanged);
    _videoLoopController.removeListener(_onVideoLoopChanged);
    widget.caregiverDriveController.removeListener(_onDriveChanged);

    _controller.dispose();
    _flashlightController.dispose();
    _lightSensorController.dispose();
    _videoLoopController.dispose();

    super.dispose();
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

      final lux = _lightSensorController.currentLux;
      if (lux != null) {
        await _flashlightController.updateLux(lux);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _controller,
        _flashlightController,
        _lightSensorController,
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
                    isActive: _controller.isFallDetectionActive,
                    onTap: _controller.simulateFallAlert,
                  ),
                  const SizedBox(height: 24),
                ],
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
