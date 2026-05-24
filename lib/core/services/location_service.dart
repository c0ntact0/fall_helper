import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart';

class DeviceLocation {
  final double latitude;
  final double longitude;

  const DeviceLocation({required this.latitude, required this.longitude});

  String get googleMapsLink =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
}

enum BackgroundLocationStatus {
  ready,
  needsForegroundPermission,
  needsBackgroundPermission,
  locationServicesDisabled,
  deniedForever,
}

class LocationService {
  static const Duration _currentLocationTimeout = Duration(seconds: 4);

  Future<DeviceLocation> getCurrentLocation() async {
    await _ensureForegroundLocationAvailable();

    final Position? position = await _getBestAvailablePosition();

    if (position == null) {
      throw Exception('Não foi possível obter a localização.');
    }

    return DeviceLocation(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  Future<void> _ensureForegroundLocationAvailable() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Os serviços de localização estão desligados.');
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception('Permissão de localização negada.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Permissão de localização negada permanentemente.');
    }
  }

  Future<Position?> _getBestAvailablePosition() async {
    try {
      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      ).timeout(_currentLocationTimeout);

      return position;
    } on TimeoutException {
      return _getLastKnownPositionSafe();
    } catch (_) {
      return _getLastKnownPositionSafe();
    }
  }

  Future<Position?> _getLastKnownPositionSafe() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (_) {
      return null;
    }
  }

  Future<BackgroundLocationStatus> ensureBackgroundLocationPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return BackgroundLocationStatus.locationServicesDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return BackgroundLocationStatus.needsForegroundPermission;
    }

    if (permission == LocationPermission.deniedForever) {
      return BackgroundLocationStatus.deniedForever;
    }

    if (_hasBackgroundLocation(permission)) {
      return BackgroundLocationStatus.ready;
    }

    if (Platform.isAndroid) {
      final LocationPermission secondAttempt =
          await Geolocator.requestPermission();

      if (_hasBackgroundLocation(secondAttempt)) {
        return BackgroundLocationStatus.ready;
      }

      if (secondAttempt == LocationPermission.deniedForever) {
        return BackgroundLocationStatus.deniedForever;
      }

      return BackgroundLocationStatus.needsBackgroundPermission;
    }

    return BackgroundLocationStatus.ready;
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  Future<LocationPermission> getPermission() async {
    return Geolocator.checkPermission();
  }

  Future<bool> isLocationServiceEnabled() async {
    return Geolocator.isLocationServiceEnabled();
  }

  bool _hasBackgroundLocation(LocationPermission permission) {
    return permission == LocationPermission.always;
  }
}
