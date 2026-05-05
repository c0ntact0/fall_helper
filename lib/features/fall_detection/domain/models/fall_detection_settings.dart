class FallDetectionSettings {
  final double impactThresholdMs2;
  final double rotationThresholdRadS;
  final double immobilityThresholdMs2;
  final Duration rotationWindow;
  final Duration immobilityWindow;
  final Duration immobilityRequiredDuration;
  final Duration cooldown;

  const FallDetectionSettings({
    required this.impactThresholdMs2,
    required this.rotationThresholdRadS,
    required this.immobilityThresholdMs2,
    required this.rotationWindow,
    required this.immobilityWindow,
    required this.immobilityRequiredDuration,
    required this.cooldown,
  });

  const FallDetectionSettings.defaults()
    : impactThresholdMs2 = 18.0,
      rotationThresholdRadS = 2.5,
      immobilityThresholdMs2 = 1.2,
      rotationWindow = const Duration(milliseconds: 800),
      immobilityWindow = const Duration(seconds: 4),
      immobilityRequiredDuration = const Duration(milliseconds: 1500),
      cooldown = const Duration(seconds: 15);
}
