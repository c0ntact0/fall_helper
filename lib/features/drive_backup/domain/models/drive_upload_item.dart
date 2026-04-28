class DriveUploadItem {
  final String localPath;
  final String remoteName;
  final String mimeType;

  const DriveUploadItem({
    required this.localPath,
    required this.remoteName,
    required this.mimeType,
  });
}
