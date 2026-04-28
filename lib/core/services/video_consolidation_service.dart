import 'dart:io';

import 'package:flutter/services.dart';

class VideoConsolidationResult {
  final String outputPath;

  const VideoConsolidationResult({required this.outputPath});
}

class VideoConsolidationService {
  static const MethodChannel _channel = MethodChannel(
    'fall_helper/video_consolidation',
  );

  Future<VideoConsolidationResult> consolidateEvidenceFolder(
    String evidenceFolderPath,
  ) async {
    final directory = Directory(evidenceFolderPath);

    if (!await directory.exists()) {
      throw Exception('Pasta de evidência não encontrada: $evidenceFolderPath');
    }

    final segmentFiles = <File>[];

    await for (final entity in directory.list()) {
      if (entity is File &&
          entity.path.toLowerCase().endsWith('.mp4') &&
          entity.uri.pathSegments.last.toLowerCase().startsWith('seg_')) {
        segmentFiles.add(entity);
      }
    }

    segmentFiles.sort(
      (a, b) => a.path.toLowerCase().compareTo(b.path.toLowerCase()),
    );

    if (segmentFiles.isEmpty) {
      throw Exception(
        'Não existem segmentos de vídeo para consolidar em $evidenceFolderPath',
      );
    }

    final outputPath =
        '$evidenceFolderPath${Platform.pathSeparator}alert_video.mp4';

    final result = await _channel
        .invokeMethod<String>('consolidateSegments', <String, dynamic>{
          'segmentPaths': segmentFiles.map((file) => file.path).toList(),
          'outputPath': outputPath,
        });

    if (result == null || result.trim().isEmpty) {
      throw Exception('A consolidação devolveu um caminho vazio.');
    }

    return VideoConsolidationResult(outputPath: result);
  }
}
