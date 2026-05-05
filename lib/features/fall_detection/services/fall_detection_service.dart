import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../domain/models/fall_detection_settings.dart';
import '../domain/models/fall_event.dart';

class FallDetectionService {
  FallDetectionService({
    FallDetectionSettings settings = const FallDetectionSettings.defaults(),
  }) : _settings = settings;

  static const bool debugSensorValues = true;
  static const Duration _logThrottleDuration = Duration(milliseconds: 300);

  final FallDetectionSettings _settings;

  StreamSubscription<UserAccelerometerEvent>? _userAccelerometerSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  DateTime? _impactDetectedAt;
  double _impactMagnitude = 0.0;
  bool _rotationConfirmed = false;

  /// Estado do sensor/dispositivo, não do candidato atual.
  bool _gyroAvailable = true;

  DateTime? _immobilityStartedAt;
  DateTime? _cooldownUntil;

  DateTime? _lastAccelerometerLogAt;
  DateTime? _lastGyroscopeLogAt;

  Future<void> start({
    required Future<void> Function(FallEvent event) onFallDetected,
    void Function(Object error)? onError,
  }) async {
    if (_isRunning) return;

    _resetCandidate();

    _userAccelerometerSubscription =
        userAccelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (event) async {
            try {
              await _handleUserAccelerometerEvent(
                event,
                onFallDetected: onFallDetected,
              );
            } catch (error) {
              onError?.call(error);
            }
          },
          onError: (error) {
            onError?.call(error);
          },
          cancelOnError: false,
        );

    _gyroscopeSubscription =
        gyroscopeEventStream(
          samplingPeriod: SensorInterval.gameInterval,
        ).listen(
          (event) {
            _handleGyroscopeEvent(event);
          },
          onError: (error) {
            _gyroAvailable = false;
            onError?.call(error);
          },
          cancelOnError: false,
        );

    _isRunning = true;
  }

  Future<void> stop() async {
    await _userAccelerometerSubscription?.cancel();
    await _gyroscopeSubscription?.cancel();
    _userAccelerometerSubscription = null;
    _gyroscopeSubscription = null;
    _isRunning = false;
    _resetCandidate();
  }

  Future<void> _handleUserAccelerometerEvent(
    UserAccelerometerEvent event, {
    required Future<void> Function(FallEvent event) onFallDetected,
  }) async {
    final now = DateTime.now();

    if (_cooldownUntil != null && now.isBefore(_cooldownUntil!)) {
      return;
    }

    final accelerationMagnitude = _magnitude(event.x, event.y, event.z);

    _logAccelerometer(event, accelerationMagnitude, now);

    if (_impactDetectedAt == null) {
      if (accelerationMagnitude >= _settings.impactThresholdMs2) {
        _impactDetectedAt = now;
        _impactMagnitude = accelerationMagnitude;
        _rotationConfirmed = false;
        _immobilityStartedAt = null;

        if (debugSensorValues) {
          debugPrint(
            'FALL | Impact detected '
            'mag=${_impactMagnitude.toStringAsFixed(2)} '
            'threshold=${_settings.impactThresholdMs2.toStringAsFixed(2)}',
          );
        }
      }
      return;
    }

    final elapsedSinceImpact = now.difference(_impactDetectedAt!);

    if (elapsedSinceImpact > _settings.immobilityWindow) {
      if (debugSensorValues) {
        debugPrint(
          'FALL | Candidate reset: immobility window expired '
          '(${elapsedSinceImpact.inMilliseconds} ms)',
        );
      }
      _resetCandidate();
      return;
    }

    if (accelerationMagnitude <= _settings.immobilityThresholdMs2) {
      _immobilityStartedAt ??= now;

      final immobilityDuration = now.difference(_immobilityStartedAt!);

      final bool canConfirmWithoutGyro = !_gyroAvailable;
      final bool motionConfirmed = _rotationConfirmed || canConfirmWithoutGyro;

      if (debugSensorValues) {
        debugPrint(
          'FALL | Immobility candidate '
          'mag=${accelerationMagnitude.toStringAsFixed(2)} '
          'immobilityMs=${immobilityDuration.inMilliseconds} '
          'rotationConfirmed=$_rotationConfirmed '
          'gyroAvailable=$_gyroAvailable',
        );
      }

      if (motionConfirmed &&
          immobilityDuration >= _settings.immobilityRequiredDuration) {
        final fallEvent = FallEvent(
          detectedAt: now,
          impactMagnitude: _impactMagnitude,
          rotationConfirmed: _rotationConfirmed,
          immobilityDuration: immobilityDuration,
        );

        _cooldownUntil = now.add(_settings.cooldown);

        if (debugSensorValues) {
          debugPrint(
            'FALL | Confirmed '
            'impact=${fallEvent.impactMagnitude.toStringAsFixed(2)} '
            'rotationConfirmed=${fallEvent.rotationConfirmed} '
            'immobilityMs=${fallEvent.immobilityDuration.inMilliseconds} '
            'cooldownUntil=$_cooldownUntil',
          );
        }

        _resetCandidate();
        await onFallDetected(fallEvent);
      }
    } else {
      if (_immobilityStartedAt != null && debugSensorValues) {
        debugPrint(
          'FALL | Immobility interrupted '
          'mag=${accelerationMagnitude.toStringAsFixed(2)}',
        );
      }
      _immobilityStartedAt = null;
    }
  }

  void _handleGyroscopeEvent(GyroscopeEvent event) {
    if (_impactDetectedAt == null) return;

    final now = DateTime.now();
    final elapsedSinceImpact = now.difference(_impactDetectedAt!);

    final rotationMagnitude = _magnitude(event.x, event.y, event.z);

    _logGyroscope(event, rotationMagnitude, now);

    if (elapsedSinceImpact > _settings.rotationWindow) {
      return;
    }

    if (rotationMagnitude >= _settings.rotationThresholdRadS) {
      _rotationConfirmed = true;

      if (debugSensorValues) {
        debugPrint(
          'FALL | Rotation confirmed '
          'mag=${rotationMagnitude.toStringAsFixed(2)} '
          'threshold=${_settings.rotationThresholdRadS.toStringAsFixed(2)} '
          'elapsedMs=${elapsedSinceImpact.inMilliseconds}',
        );
      }
    }
  }

  void _logAccelerometer(
    UserAccelerometerEvent event,
    double magnitude,
    DateTime now,
  ) {
    if (!debugSensorValues) return;

    if (_lastAccelerometerLogAt == null ||
        now.difference(_lastAccelerometerLogAt!) > _logThrottleDuration) {
      _lastAccelerometerLogAt = now;

      debugPrint(
        'ACC | x=${event.x.toStringAsFixed(2)} '
        'y=${event.y.toStringAsFixed(2)} '
        'z=${event.z.toStringAsFixed(2)} '
        'mag=${magnitude.toStringAsFixed(2)}',
      );
    }
  }

  void _logGyroscope(GyroscopeEvent event, double magnitude, DateTime now) {
    if (!debugSensorValues) return;

    if (_lastGyroscopeLogAt == null ||
        now.difference(_lastGyroscopeLogAt!) > _logThrottleDuration) {
      _lastGyroscopeLogAt = now;

      debugPrint(
        'GYRO | x=${event.x.toStringAsFixed(2)} '
        'y=${event.y.toStringAsFixed(2)} '
        'z=${event.z.toStringAsFixed(2)} '
        'mag=${magnitude.toStringAsFixed(2)}',
      );
    }
  }

  double _magnitude(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z);
  }

  void _resetCandidate() {
    _impactDetectedAt = null;
    _impactMagnitude = 0.0;
    _rotationConfirmed = false;
    _immobilityStartedAt = null;
  }

  Future<void> dispose() async {
    await stop();
  }
}
