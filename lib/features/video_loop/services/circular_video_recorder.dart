import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';

import '../../../core/services/video_storage_service.dart';
import '../domain/models/video_loop_settings.dart';
import '../domain/models/video_segment.dart';

class CircularVideoRecorder {
  CircularVideoRecorder({required VideoStorageService storageService})
    : _storageService = storageService;

  final VideoStorageService _storageService;

  final Queue<VideoSegment> _segments = Queue<VideoSegment>();

  CameraController? _cameraController;
  bool _isRunning = false;
  bool _isPreserving = false;
  bool _isInitialized = false;

  bool get isRunning => _isRunning;
  bool get isPreserving => _isPreserving;
  bool get isInitialized => _isInitialized;
  CameraController? get cameraController => _cameraController;

  Duration get retainedDuration =>
      _segments.fold(Duration.zero, (sum, segment) => sum + segment.duration);

  List<VideoSegment> get segmentsSnapshot => List.unmodifiable(_segments);

  ResolutionPreset _mapQuality(VideoLoopQuality quality) {
    switch (quality) {
      case VideoLoopQuality.p480:
        return ResolutionPreset.medium;
      case VideoLoopQuality.p720:
        return ResolutionPreset.high;
    }
  }

  Future<void> initialize(VideoLoopSettings settings) async {
    if (_isInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return;
    }

    final cameras = await availableCameras();
    
    for (final CameraDescription(:name,:lensDirection,:lensType,:sensorOrientation) in cameras) {
        debugPrint('Camera name: $name | Lens Dir.: $lensDirection | Lens Type: $lensType | Sensor Degrees: $sensorOrientation');
    }
    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    debugPrint('Camera description: $backCamera');

    final controller = CameraController(
      backCamera,
      _mapQuality(settings.quality),
      enableAudio: settings.withAudio,
      fps: settings.fps,
    );

    await controller.initialize();

    _cameraController = controller;
    _isInitialized = true;
  }

  Future<void> start(VideoLoopSettings settings) async {
    if (_isRunning) return;

    if (!_isInitialized || _cameraController == null) {
      await initialize(settings);
    }

    _isRunning = true;

    while (_isRunning) {
      await _recordSingleSegment(settings);
    }
  }

  Future<void> stop({bool clearBuffer = false}) async {
    _isRunning = false;

    final controller = _cameraController;
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        final file = await controller.stopVideoRecording();
        await _storageService.deleteFileIfExists(file.path);
      } catch (_) {}
    }

    if (clearBuffer) {
      await _clearSegments();
      await _storageService.clearAllTemporaryVideoArtifacts();
    }
  }

  Future<void> shutdown({bool clearBuffer = true}) async {
    await stop(clearBuffer: clearBuffer);

    final controller = _cameraController;
    _cameraController = null;
    _isInitialized = false;

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }

    if (clearBuffer) {
      await _storageService.clearAllTemporaryVideoArtifacts();
    }
  }

  Future<void> _recordSingleSegment(VideoLoopSettings settings) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final tempPath = await _storageService.nextTempSegmentPath();
    final startedAt = DateTime.now();

    await controller.startVideoRecording();

    await Future.delayed(Duration(seconds: settings.segmentSeconds));

    if (!_isRunning) {
      if (controller.value.isRecordingVideo) {
        try {
          final file = await controller.stopVideoRecording();
          await _storageService.deleteFileIfExists(file.path);
        } catch (_) {}
      }
      return;
    }

    if (!controller.value.isRecordingVideo) return;

    final file = await controller.stopVideoRecording();
    final endedAt = DateTime.now();

    final targetFile = File(tempPath);
    await File(file.path).copy(targetFile.path);
    await _storageService.deleteFileIfExists(file.path);

    final segment = VideoSegment(
      path: targetFile.path,
      startedAt: startedAt,
      endedAt: endedAt,
      duration: endedAt.difference(startedAt),
    );

    _segments.add(segment);
    await _trimBuffer(settings);
  }

  Future<void> _trimBuffer(VideoLoopSettings settings) async {
    while (retainedDuration.inSeconds > settings.bufferSeconds &&
        _segments.isNotEmpty) {
      final oldest = _segments.removeFirst();
      await _storageService.deleteFileIfExists(oldest.path);
    }
  }

  Future<List<VideoSegment>> freezeSegments() async {
    _isPreserving = true;
    _isRunning = false;

    final controller = _cameraController;
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        final file = await controller.stopVideoRecording();
        await _storageService.deleteFileIfExists(file.path);
      } catch (_) {}
    }

    _isPreserving = false;

    // Limpa cache residual do plugin, mas mantém temp_segments porque é daí
    // que a evidência vai ser copiada.
    await _storageService.clearTemporaryCacheVideos();

    return List.unmodifiable(_segments);
  }

  Future<void> _clearSegments() async {
    while (_segments.isNotEmpty) {
      final segment = _segments.removeFirst();
      await _storageService.deleteFileIfExists(segment.path);
    }

    await _storageService.clearTempSegmentsDir();
  }

  Future<void> dispose() async {
    await shutdown(clearBuffer: false);
  }
}
