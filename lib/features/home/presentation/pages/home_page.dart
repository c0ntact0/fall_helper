import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/routes.dart';
import '../../../../core/services/storage_service.dart';
import '../../../settings/domain/models/caregiver.dart';
import '../../../settings/domain/models/user_feature_settings.dart';
import '../widgets/fall_detection_card.dart';
import '../widgets/flashlight_card.dart';
import '../widgets/panic_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final StorageService _storageService = StorageService();

  bool _isLoading = true;

  bool _isFallDetectionActive = true;
  bool _isFlashlightActive = false;

  bool _isPanicInProgress = false;
  double _panicProgress = 0.0;

  bool _showFallDetectionButton = true;
  bool _showPanicButton = true;
  String _caregiverName = 'Cuidador';

  Timer? _panicTimer;

  @override
  void initState() {
    super.initState();
    _loadHomeSettings();
  }

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadHomeSettings() async {
    final Caregiver caregiver = await _storageService.loadCaregiver();
    final UserFeatureSettings userFeatureSettings = await _storageService
        .loadUserFeatureSettings();

    if (!mounted) return;

    setState(() {
      _caregiverName = caregiver.name;
      _showFallDetectionButton = userFeatureSettings.showFallDetectionButton;
      _showPanicButton = userFeatureSettings.showPanicButton;
      _isLoading = false;
    });
  }

  Future<void> _openSettings() async {
    await Navigator.pushNamed(context, AppRoutes.pinLogin);
    await _loadHomeSettings();
  }

  void _toggleFallDetection() {
    setState(() {
      _isFallDetectionActive = !_isFallDetectionActive;
    });
  }

  void _toggleFlashlight() {
    setState(() {
      _isFlashlightActive = !_isFlashlightActive;
    });
  }

  void _startPanicFlow() {
    if (_isPanicInProgress) return;

    setState(() {
      _isPanicInProgress = true;
      _panicProgress = 0.0;
    });

    const totalDuration = Duration(seconds: 5);
    const stepDuration = Duration(milliseconds: 100);

    final int totalSteps =
        totalDuration.inMilliseconds ~/ stepDuration.inMilliseconds;

    int currentStep = 0;

    _panicTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;

      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _panicProgress = currentStep / totalSteps;
      });

      if (currentStep >= totalSteps) {
        timer.cancel();

        setState(() {
          _panicProgress = 1.0;
        });

        _performPanicCall();
      }
    });
  }

  void _performPanicCall() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;

      setState(() {
        _isPanicInProgress = false;
        _panicProgress = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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
            if (_showFallDetectionButton) ...[
              FallDetectionCard(
                isActive: _isFallDetectionActive,
                onTap: _toggleFallDetection,
              ),
              const SizedBox(height: 24),
            ],
            FlashlightCard(
              isActive: _isFlashlightActive,
              onTap: _toggleFlashlight,
            ),
            if (_showPanicButton) ...[
              const SizedBox(height: 24),
              PanicCard(
                caregiverName: _caregiverName,
                isInProgress: _isPanicInProgress,
                progress: _panicProgress,
                onTap: _startPanicFlow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
