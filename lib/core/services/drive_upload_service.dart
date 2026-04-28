import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../features/drive_backup/domain/models/drive_upload_item.dart';
import '../../features/drive_backup/domain/models/drive_upload_result.dart';

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
    final uploadedIds = <String>[];

    for (final item in items) {
      final fileId = await _uploadSingleFileResumable(
        accessToken: accessToken,
        parentFolderId: parentFolderId,
        item: item,
      );
      uploadedIds.add(fileId);
    }

    return DriveUploadResult(
      alertFolderId: parentFolderId,
      uploadedFileIds: uploadedIds,
      uploadedAt: DateTime.now(),
    );
  }

  Future<String> _uploadSingleFileResumable({
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
      '$_driveUploadBase?uploadType=resumable&fields=id',
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
    return uploadJson['id'] as String;
  }
}
