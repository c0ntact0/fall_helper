class UserFeatureSettings {
  final bool showFallDetectionButton;
  final bool showPanicButton;
  final bool enableAutomaticFlashlightMode;
  final double flashlightDarknessThresholdLux;

  const UserFeatureSettings({
    required this.showFallDetectionButton,
    required this.showPanicButton,
    required this.enableAutomaticFlashlightMode,
    required this.flashlightDarknessThresholdLux,
  });

  UserFeatureSettings copyWith({
    bool? showFallDetectionButton,
    bool? showPanicButton,
    bool? enableAutomaticFlashlightMode,
    double? flashlightDarknessThresholdLux,
  }) {
    return UserFeatureSettings(
      showFallDetectionButton:
          showFallDetectionButton ?? this.showFallDetectionButton,
      showPanicButton: showPanicButton ?? this.showPanicButton,
      enableAutomaticFlashlightMode:
          enableAutomaticFlashlightMode ?? this.enableAutomaticFlashlightMode,
      flashlightDarknessThresholdLux:
          flashlightDarknessThresholdLux ?? this.flashlightDarknessThresholdLux,
    );
  }
}
