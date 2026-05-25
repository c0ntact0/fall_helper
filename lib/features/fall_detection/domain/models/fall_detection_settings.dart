class FallDetectionSettings {
  final double freeFallThresholdMs2;
  final Duration freeFallRequiredDuration;
  final Duration freeFallWindowBeforeImpact;

  final double impactThresholdMs2;
  final double rotationThresholdRadS;
  final double immobilityThresholdMs2;

  final Duration rotationWindow;
  final Duration immobilityWindow;
  final Duration immobilityRequiredDuration;
  final Duration cooldown;

  const FallDetectionSettings({
    required this.freeFallThresholdMs2,
    required this.freeFallRequiredDuration,
    required this.freeFallWindowBeforeImpact,
    required this.impactThresholdMs2,
    required this.rotationThresholdRadS,
    required this.immobilityThresholdMs2,
    required this.rotationWindow,
    required this.immobilityWindow,
    required this.immobilityRequiredDuration,
    required this.cooldown,
  });

  const FallDetectionSettings.defaults()
    : freeFallThresholdMs2 = 1.8,
      freeFallRequiredDuration = const Duration(milliseconds: 150),
      freeFallWindowBeforeImpact = const Duration(milliseconds: 600),
      impactThresholdMs2 = 25.0,
      rotationThresholdRadS = 3.0,
      immobilityThresholdMs2 = 1.2,
      rotationWindow = const Duration(milliseconds: 800),
      immobilityWindow = const Duration(seconds: 4),
      immobilityRequiredDuration = const Duration(milliseconds: 1500),
      cooldown = const Duration(seconds: 15);
}
