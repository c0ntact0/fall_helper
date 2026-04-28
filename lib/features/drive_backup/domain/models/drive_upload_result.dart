class DriveUploadResult {
  final String alertFolderId;
  final List<String> uploadedFileIds;
  final DateTime uploadedAt;

  const DriveUploadResult({
    required this.alertFolderId,
    required this.uploadedFileIds,
    required this.uploadedAt,
  });
}
