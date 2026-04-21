class UserFeatureSettings {
  final bool showFallDetectionButton;
  final bool showPanicButton;

  const UserFeatureSettings({
    required this.showFallDetectionButton,
    required this.showPanicButton,
  });

  UserFeatureSettings copyWith({
    bool? showFallDetectionButton,
    bool? showPanicButton,
  }) {
    return UserFeatureSettings(
      showFallDetectionButton:
          showFallDetectionButton ?? this.showFallDetectionButton,
      showPanicButton: showPanicButton ?? this.showPanicButton,
    );
  }
}
