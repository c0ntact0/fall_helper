class FallEvent {
  final DateTime detectedAt;
  final double impactMagnitude;
  final bool rotationConfirmed;
  final Duration immobilityDuration;

  const FallEvent({
    required this.detectedAt,
    required this.impactMagnitude,
    required this.rotationConfirmed,
    required this.immobilityDuration,
  });
}
