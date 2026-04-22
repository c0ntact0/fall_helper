import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/services/phone_call_service.dart';
import '../../../../core/services/storage_service.dart';
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
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();

    _controller = HomeController(
      storageService: StorageService(),
      phoneCallService: PhoneCallService(),
    );

    _controller.addListener(_onControllerChanged);
    _controller.loadHomeSettings();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
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

  Future<void> _openSettings() async {
    final result = await Navigator.pushNamed(context, AppRoutes.pinLogin);

    if (result == true) {
      await _controller.loadHomeSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
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
                  isActive: _controller.isFlashlightActive,
                  onTap: _controller.toggleFlashlight,
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
