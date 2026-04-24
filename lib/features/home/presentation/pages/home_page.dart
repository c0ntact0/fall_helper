import 'package:flutter/material.dart';

import '../../../../core/services/flashlight_service.dart';
import '../../../../core/services/light_sensor_service.dart';
import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../flashlight/presentation/controllers/flashlight_controller.dart';
import '../../../light_sensor/presentation/controllers/light_sensor_controller.dart';
import '../../../settings/presentation/pages/settings_host_page.dart';
import '../controllers/home_controller.dart';
import '../widgets/fall_detection_card.dart';
import '../widgets/flashlight_card.dart';
import '../widgets/panic_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final FlashlightController _flashlightController;
  late final LightSensorController _lightSensorController;
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();

    _flashlightController = FlashlightController(
      flashlightService: FlashlightService(),
    );

    _lightSensorController = LightSensorController(
      lightSensorService: LightSensorService(),
    );

    _controller = HomeController(
      storageService: StorageService(),
      phoneCallService: PhoneCallService(),
      flashlightController: _flashlightController,
    );

    _controller.addListener(_onControllerChanged);
    _flashlightController.addListener(_onFlashlightChanged);
    _lightSensorController.addListener(_onLightSensorChanged);

    _initializePage();
  }

  Future<void> _initializePage() async {
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

    _controller.dispose();
    _flashlightController.dispose();
    _lightSensorController.dispose();

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

  Future<void> _openSettings() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SettingsHostPage(lightSensorController: _lightSensorController),
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
      ]),
      builder: (context, _) {
        if (_controller.isLoading) {
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
                    onTap: _controller.toggleFallDetection,
                  ),
                  const SizedBox(height: 24),
                ],
                FlashlightCard(
                  isActive: _flashlightController.isOn,
                  isAvailable: _flashlightController.isAvailable,
                  autoModeEnabled: _flashlightController.autoModeEnabled,
                  manualOverrideActive:
                      _flashlightController.manualOverrideActive,
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
