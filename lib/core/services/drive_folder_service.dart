import 'dart:convert';

import 'package:http/http.dart' as http;

abstract class DriveFolderService {
  Future<String> getOrCreateRootFolder({
    required String accessToken,
    required String folderName,
  });

  Future<String> createAlertFolder({
    required String accessToken,
    required String rootFolderId,
    required String folderName,
  });
}

class DriveFolderServiceImpl implements DriveFolderService {
  static const String _driveFilesBase =
      'https://www.googleapis.com/drive/v3/files';

  Map<String, String> _headers(String accessToken) {
    return <String, String>{
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
  }

  @override
  Future<String> getOrCreateRootFolder({
    required String accessToken,
    required String folderName,
  }) async {
    final query =
        "mimeType='application/vnd.google-apps.folder' and "
        "name='${folderName.replaceAll("'", "\\'")}' and trashed=false";

    final searchUri = Uri.parse(
      '$_driveFilesBase?q=${Uri.encodeQueryComponent(query)}&fields=files(id,name)',
    );

    final searchResponse = await http.get(
      searchUri,
      headers: _headers(accessToken),
    );

    if (searchResponse.statusCode != 200) {
      throw Exception(
        'Falha ao procurar pasta raiz no Drive: ${searchResponse.statusCode} ${searchResponse.body}',
      );
    }

    final searchJson = jsonDecode(searchResponse.body) as Map<String, dynamic>;
    final files = (searchJson['files'] as List<dynamic>?) ?? <dynamic>[];

    if (files.isNotEmpty) {
      final first = files.first as Map<String, dynamic>;
      return first['id'] as String;
    }

    final createResponse = await http.post(
      Uri.parse(_driveFilesBase),
      headers: _headers(accessToken),
      body: jsonEncode(<String, dynamic>{
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
      }),
    );

    if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
      throw Exception(
        'Falha ao criar pasta raiz no Drive: ${createResponse.statusCode} ${createResponse.body}',
      );
    }

    final createJson = jsonDecode(createResponse.body) as Map<String, dynamic>;
    return createJson['id'] as String;
  }

  @override
  Future<String> createAlertFolder({
    required String accessToken,
    required String rootFolderId,
    required String folderName,
  }) async {
    final createResponse = await http.post(
      Uri.parse(_driveFilesBase),
      headers: _headers(accessToken),
      body: jsonEncode(<String, dynamic>{
        'name': folderName,
        'mimeType': 'application/vnd.google-apps.folder',
        'parents': <String>[rootFolderId],
      }),
    );

    if (createResponse.statusCode != 200 && createResponse.statusCode != 201) {
      throw Exception(
        'Falha ao criar pasta do alerta no Drive: ${createResponse.statusCode} ${createResponse.body}',
      );
    }

    final createJson = jsonDecode(createResponse.body) as Map<String, dynamic>;
    return createJson['id'] as String;
  }
}
