class DriveUploadResult {
  final String alertFolderId;
  final List<String> uploadedFileIds;
  final DateTime uploadedAt;
  final String? alertVideoFileId;
  final String? alertVideoWebViewLink;

  const DriveUploadResult({
    required this.alertFolderId,
    required this.uploadedFileIds,
    required this.uploadedAt,
    required this.alertVideoFileId,
    required this.alertVideoWebViewLink,
  });
}
