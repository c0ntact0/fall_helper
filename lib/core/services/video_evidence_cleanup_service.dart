import 'dart:io';

class VideoEvidenceCleanupService {
  Future<void> deleteEvidenceFolder(String folderPath) async {
    final directory = Directory(folderPath);

    if (!await directory.exists()) {
      return;
    }

    await directory.delete(recursive: true);
  }
}
