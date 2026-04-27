import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../features/video_loop/domain/models/video_evidence.dart';
import '../../features/video_loop/domain/models/video_segment.dart';

class VideoStorageService {
  Future<Directory> _baseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final base = Directory('${dir.path}/video_loop');
    if (!await base.exists()) {
      await base.create(recursive: true);
    }
    debugPrint('Video loop base dir: ${base.path}');
    return base;
  }

  Future<Directory> getTempSegmentsDir() async {
    final base = await _baseDir();
    final dir = Directory('${base.path}/temp_segments');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> getEvidenceDir() async {
    final base = await _baseDir();
    final dir = Directory('${base.path}/evidence');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> nextTempSegmentPath() async {
    final dir = await getTempSegmentsDir();
    final now = DateTime.now().millisecondsSinceEpoch;
    return '${dir.path}/segment_$now.mp4';
  }

  Future<void> deleteFileIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearTempSegmentsDir() async {
    final dir = await getTempSegmentsDir();
    if (!await dir.exists()) return;

    await for (final entity in dir.list()) {
      if (entity is File) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> clearTemporaryCacheVideos() async {
    final tempDir = await getTemporaryDirectory();
    if (!await tempDir.exists()) return;

    await for (final entity in tempDir.list()) {
      if (entity is! File) continue;

      final name = entity.uri.pathSegments.last.toLowerCase();

      // Conservador: apaga apenas mp4 temporários típicos do fluxo atual.
      if (name.endsWith('.mp4') &&
          (name.startsWith('rec') || name.startsWith('segment_'))) {
        try {
          await entity.delete();
        } catch (_) {}
      }
    }
  }

  Future<void> clearAllTemporaryVideoArtifacts() async {
    await clearTempSegmentsDir();
    await clearTemporaryCacheVideos();
  }

  Future<VideoEvidence> preserveEvidence({
    required List<VideoSegment> segments,
    required DateTime alertTime,
  }) async {
    final evidenceRoot = await getEvidenceDir();
    final folderName = alertTime.toIso8601String().replaceAll(':', '-');
    final folder = Directory('${evidenceRoot.path}/$folderName');
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final copiedSegments = <VideoSegment>[];

    for (var i = 0; i < segments.length; i++) {
      final source = File(segments[i].path);
      if (!await source.exists()) continue;

      final destPath = '${folder.path}/seg_${i.toString().padLeft(3, '0')}.mp4';
      await source.copy(destPath);

      copiedSegments.add(
        VideoSegment(
          path: destPath,
          startedAt: segments[i].startedAt,
          endedAt: segments[i].endedAt,
          duration: segments[i].duration,
        ),
      );
    }

    final retained = copiedSegments.fold<Duration>(
      Duration.zero,
      (sum, segment) => sum + segment.duration,
    );

    final manifest = File('${folder.path}/manifest.json');
    await manifest.writeAsString(
      jsonEncode({
        'alertTime': alertTime.toIso8601String(),
        'retainedDurationSeconds': retained.inSeconds,
        'segments': copiedSegments
            .map(
              (s) => {
                'path': s.path,
                'startedAt': s.startedAt.toIso8601String(),
                'endedAt': s.endedAt.toIso8601String(),
                'durationMs': s.duration.inMilliseconds,
              },
            )
            .toList(),
      }),
    );

    return VideoEvidence(
      segments: copiedSegments,
      alertTime: alertTime,
      retainedDuration: retained,
      folderPath: folder.path,
    );
  }
}