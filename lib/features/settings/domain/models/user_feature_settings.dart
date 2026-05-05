class UserFeatureSettings {
  final bool showFallDetectionButton;
  final bool showPanicButton;
  final bool showSimulateFallButton;
  final bool enableAutomaticFlashlightMode;
  final double flashlightDarknessThresholdLux;
  final bool fallDetectionEnabled;

  const UserFeatureSettings({
    required this.showFallDetectionButton,
    required this.showPanicButton,
    required this.showSimulateFallButton,
    required this.enableAutomaticFlashlightMode,
    required this.flashlightDarknessThresholdLux,
    required this.fallDetectionEnabled,
  });

  UserFeatureSettings copyWith({
    bool? showFallDetectionButton,
    bool? showPanicButton,
    bool? showSimulateFallButton,
    bool? enableAutomaticFlashlightMode,
    double? flashlightDarknessThresholdLux,
    bool? fallDetectionEnabled,
  }) {
    return UserFeatureSettings(
      showFallDetectionButton:
          showFallDetectionButton ?? this.showFallDetectionButton,
      showPanicButton: showPanicButton ?? this.showPanicButton,
      showSimulateFallButton:
          showSimulateFallButton ?? this.showSimulateFallButton,
      enableAutomaticFlashlightMode:
          enableAutomaticFlashlightMode ?? this.enableAutomaticFlashlightMode,
      flashlightDarknessThresholdLux:
          flashlightDarknessThresholdLux ?? this.flashlightDarknessThresholdLux,
      fallDetectionEnabled: fallDetectionEnabled ?? this.fallDetectionEnabled,
    );
  }
}
