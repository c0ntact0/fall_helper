import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/drive_backup/domain/models/drive_upload_item.dart';
import '../../features/drive_backup/domain/models/drive_upload_result.dart';

class _UploadedDriveFile {
  final String fileId;
  final String remoteName;

  const _UploadedDriveFile({required this.fileId, required this.remoteName});
}

abstract class DriveUploadService {
  Future<DriveUploadResult> uploadAlertFiles({
    required String accessToken,
    required String parentFolderId,
    required List<DriveUploadItem> items,
  });
}



class DriveUploadServiceImpl implements DriveUploadService {
  static const String _driveUploadBase =
      'https://www.googleapis.com/upload/drive/v3/files';
  static const String _driveFilesBase =
      'https://www.googleapis.com/drive/v3/files';

  Map<String, String> _authHeaders(String accessToken) {
    return <String, String>{'Authorization': 'Bearer $accessToken'};
  }

  @override
  Future<DriveUploadResult> uploadAlertFiles({
    required String accessToken,
    required String parentFolderId,
    required List<DriveUploadItem> items,
  }) async {
    final uploadedFiles = <_UploadedDriveFile>[];

    for (final item in items) {
      final uploaded = await _uploadSingleFileResumable(
        accessToken: accessToken,
        parentFolderId: parentFolderId,
        item: item,
      );
      uploadedFiles.add(uploaded);
    }

    String? alertVideoFileId;
    String? alertVideoWebViewLink;

    for (final file in uploadedFiles) {
      if (file.remoteName.toLowerCase() == 'alert_video.mp4') {
        alertVideoFileId = file.fileId;
        alertVideoWebViewLink = await _fetchWebViewLink(
          accessToken: accessToken,
          fileId: file.fileId,
        );
        break;
      }
    }

    return DriveUploadResult(
      alertFolderId: parentFolderId,
      uploadedFileIds: uploadedFiles.map((e) => e.fileId).toList(),
      uploadedAt: DateTime.now(),
      alertVideoFileId: alertVideoFileId,
      alertVideoWebViewLink: alertVideoWebViewLink,
    );
  }

  Future<_UploadedDriveFile> _uploadSingleFileResumable({
    required String accessToken,
    required String parentFolderId,
    required DriveUploadItem item,
  }) async {
    final file = File(item.localPath);

    if (!await file.exists()) {
      throw Exception('Ficheiro não encontrado: ${item.localPath}');
    }

    final fileLength = await file.length();

    final startSessionUri = Uri.parse(
      '$_driveUploadBase?uploadType=resumable&fields=id,name',
    );

    final startSessionResponse = await http.post(
      startSessionUri,
      headers: <String, String>{
        ..._authHeaders(accessToken),
        'Content-Type': 'application/json; charset=UTF-8',
        'X-Upload-Content-Type': item.mimeType,
        'X-Upload-Content-Length': '$fileLength',
      },
      body: jsonEncode(<String, dynamic>{
        'name': item.remoteName,
        'parents': <String>[parentFolderId],
      }),
    );

    if (startSessionResponse.statusCode != 200 &&
        startSessionResponse.statusCode != 201) {
      throw Exception(
        'Falha ao iniciar sessão resumable: ${startSessionResponse.statusCode} ${startSessionResponse.body}',
      );
    }

    final sessionUriString = startSessionResponse.headers['location'];
    if (sessionUriString == null || sessionUriString.isEmpty) {
      throw Exception('Drive não devolveu URL da sessão resumable.');
    }

    final uploadResponse = await http.put(
      Uri.parse(sessionUriString),
      headers: <String, String>{
        ..._authHeaders(accessToken),
        'Content-Length': '$fileLength',
        'Content-Type': item.mimeType,
      },
      body: await file.readAsBytes(),
    );

    if (uploadResponse.statusCode != 200 && uploadResponse.statusCode != 201) {
      throw Exception(
        'Falha no upload resumable: ${uploadResponse.statusCode} ${uploadResponse.body}',
      );
    }

    final uploadJson = jsonDecode(uploadResponse.body) as Map<String, dynamic>;

    return _UploadedDriveFile(
      fileId: uploadJson['id'] as String,
      remoteName: uploadJson['name'] as String? ?? item.remoteName,
    );
  }

  Future<String?> _fetchWebViewLink({
    required String accessToken,
    required String fileId,
  }) async {
    final uri = Uri.parse('$_driveFilesBase/$fileId?fields=id,webViewLink');

    final response = await http.get(uri, headers: _authHeaders(accessToken));

    if (response.statusCode != 200) {
      throw Exception(
        'Falha ao obter webViewLink do ficheiro: ${response.statusCode} ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['webViewLink'] as String?;
  }
}
