class CaregiverDriveSession {
  final bool isAuthorized;
  final String caregiverGoogleEmail;
  final String? caregiverDisplayName;
  final String? rootFolderId;

  const CaregiverDriveSession({
    required this.isAuthorized,
    required this.caregiverGoogleEmail,
    required this.caregiverDisplayName,
    required this.rootFolderId,
  });

  const CaregiverDriveSession.empty()
    : isAuthorized = false,
      caregiverGoogleEmail = '',
      caregiverDisplayName = null,
      rootFolderId = null;

  CaregiverDriveSession copyWith({
    bool? isAuthorized,
    String? caregiverGoogleEmail,
    String? caregiverDisplayName,
    String? rootFolderId,
  }) {
    return CaregiverDriveSession(
      isAuthorized: isAuthorized ?? this.isAuthorized,
      caregiverGoogleEmail: caregiverGoogleEmail ?? this.caregiverGoogleEmail,
      caregiverDisplayName: caregiverDisplayName ?? this.caregiverDisplayName,
      rootFolderId: rootFolderId ?? this.rootFolderId,
    );
  }

  bool get hasLinkedAccount =>
      isAuthorized &&
      caregiverGoogleEmail.trim().isNotEmpty &&
      rootFolderId != null &&
      rootFolderId!.trim().isNotEmpty;
}
