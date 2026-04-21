import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../app/routes.dart';
import '../widgets/fall_detection_card.dart';
import '../widgets/flashlight_card.dart';
import '../widgets/panic_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isFallDetectionActive = true;
  bool _isFlashlightActive = false;

  bool _isPanicInProgress = false;
  double _panicProgress = 0.0;

  Timer? _panicTimer;

  @override
  void dispose() {
    _panicTimer?.cancel();
    super.dispose();
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
    final totalSteps =
        totalDuration.inMilliseconds ~/ stepDuration.inMilliseconds;

    int currentStep = 0;

    _panicTimer = Timer.periodic(stepDuration, (timer) {
      currentStep++;

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
    // Aqui depois ligamos a chamada real ao cuidador.
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
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/logo.png',
          height: 32,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.pinLogin);
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FallDetectionCard(
              isActive: _isFallDetectionActive,
              onTap: _toggleFallDetection,
            ),
            const SizedBox(height: 24),
            FlashlightCard(
              isActive: _isFlashlightActive,
              onTap: _toggleFlashlight,
            ),
            const SizedBox(height: 24),
            PanicCard(
              caregiverName: 'Rui Loureiro',
              isInProgress: _isPanicInProgress,
              progress: _panicProgress,
              onTap: _startPanicFlow,
            ),
          ],
        ),
      ),
    );
  }
}
