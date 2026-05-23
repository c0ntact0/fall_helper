import 'dart:collection';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

import '../../../core/services/video_storage_service.dart';
import '../domain/models/video_loop_settings.dart';
import '../domain/models/video_segment.dart';

class CircularVideoRecorder {
  CircularVideoRecorder({required VideoStorageService storageService})
    : _storageService = storageService;

  final VideoStorageService _storageService;

  final Queue<VideoSegment> _segments = Queue<VideoSegment>();

  CameraController? _cameraController;
  VideoLoopSettings? _currentSettings;

  bool _isRunning = false;
  bool _isPreserving = false;
  bool _isInitialized = false;

  DateTime? _currentSegmentStartedAt;

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
    _currentSettings = settings;

    if (_isInitialized &&
        _cameraController != null &&
        _cameraController!.value.isInitialized) {
      return;
    }

    final cameras = await availableCameras();

    final backCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

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

    _currentSettings = settings;

    if (!_isInitialized || _cameraController == null) {
      await initialize(settings);
    }

    _isRunning = true;

    while (_isRunning) {
      await _recordSingleBufferSegment(settings);
    }
  }

  Future<void> stop({bool clearBuffer = false}) async {
    _isRunning = false;

    final controller = _cameraController;
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        final file = await controller.stopVideoRecording();
        _currentSegmentStartedAt = null;
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
    _currentSettings = null;
    _currentSegmentStartedAt = null;

    if (controller != null) {
      try {
        await controller.dispose();
      } catch (_) {}
    }

    if (clearBuffer) {
      await _storageService.clearAllTemporaryVideoArtifacts();
    }
  }

  Future<void> _recordSingleBufferSegment(VideoLoopSettings settings) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    final tempPath = await _storageService.nextTempSegmentPath();
    final startedAt = DateTime.now();

    _currentSegmentStartedAt = startedAt;
    await controller.startVideoRecording();

    await Future.delayed(Duration(seconds: settings.segmentSeconds));

    if (!_isRunning) {
      if (controller.value.isRecordingVideo) {
        try {
          final file = await controller.stopVideoRecording();
          _currentSegmentStartedAt = null;
          await _storageService.deleteFileIfExists(file.path);
        } catch (_) {}
      }
      return;
    }

    if (!controller.value.isRecordingVideo) return;

    final file = await controller.stopVideoRecording();
    final endedAt = DateTime.now();
    _currentSegmentStartedAt = null;

    final segment = await _persistStoppedRecording(
      sourcePath: file.path,
      targetPath: tempPath,
      startedAt: startedAt,
      endedAt: endedAt,
    );

    if (segment == null) return;

    _segments.add(segment);
    await _trimBuffer(settings);
  }

  Future<List<VideoSegment>> captureAlertSegments({
    required int postEventSeconds,
  }) async {
    final settings = _currentSettings;
    if (settings == null) {
      return const [];
    }

    _isPreserving = true;
    _isRunning = false;

    try {
      final List<VideoSegment> evidenceSegments = List<VideoSegment>.from(
        _segments,
      );

      final currentSegment = await _finalizeCurrentSegmentIfNeeded();
      if (currentSegment != null) {
        _segments.add(currentSegment);
        await _trimBuffer(settings);
        evidenceSegments.add(currentSegment);
      }

      final int extraSegments = (postEventSeconds / settings.segmentSeconds)
          .ceil();

      for (var i = 0; i < extraSegments; i++) {
        final postSegment = await _recordStandaloneSegment(settings);
        if (postSegment != null) {
          evidenceSegments.add(postSegment);
        }
      }

      await _storageService.clearTemporaryCacheVideos();

      return List<VideoSegment>.unmodifiable(evidenceSegments);
    } finally {
      _isPreserving = false;
    }
  }

  Future<VideoSegment?> _finalizeCurrentSegmentIfNeeded() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    if (!controller.value.isRecordingVideo) {
      return null;
    }

    final startedAt = _currentSegmentStartedAt ?? DateTime.now();
    final tempPath = await _storageService.nextTempSegmentPath();

    try {
      final file = await controller.stopVideoRecording();
      final endedAt = DateTime.now();
      _currentSegmentStartedAt = null;

      return await _persistStoppedRecording(
        sourcePath: file.path,
        targetPath: tempPath,
        startedAt: startedAt,
        endedAt: endedAt,
      );
    } catch (_) {
      _currentSegmentStartedAt = null;
      return null;
    }
  }

  Future<VideoSegment?> _recordStandaloneSegment(
    VideoLoopSettings settings,
  ) async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return null;
    }

    final tempPath = await _storageService.nextTempSegmentPath();
    final startedAt = DateTime.now();

    _currentSegmentStartedAt = startedAt;
    await controller.startVideoRecording();

    await Future.delayed(Duration(seconds: settings.segmentSeconds));

    if (!controller.value.isRecordingVideo) {
      _currentSegmentStartedAt = null;
      return null;
    }

    final file = await controller.stopVideoRecording();
    final endedAt = DateTime.now();
    _currentSegmentStartedAt = null;

    return await _persistStoppedRecording(
      sourcePath: file.path,
      targetPath: tempPath,
      startedAt: startedAt,
      endedAt: endedAt,
    );
  }

  Future<VideoSegment?> _persistStoppedRecording({
    required String sourcePath,
    required String targetPath,
    required DateTime startedAt,
    required DateTime endedAt,
  }) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      return null;
    }

    final targetFile = File(targetPath);
    await sourceFile.copy(targetFile.path);
    await _storageService.deleteFileIfExists(sourcePath);

    return VideoSegment(
      path: targetFile.path,
      startedAt: startedAt,
      endedAt: endedAt,
      duration: endedAt.difference(startedAt),
    );
  }

  Future<void> _trimBuffer(VideoLoopSettings settings) async {
    final int maxSegments = (settings.bufferSeconds / settings.segmentSeconds)
        .ceil();

    while (_segments.length > maxSegments && _segments.isNotEmpty) {
      final oldest = _segments.removeFirst();
      await _storageService.deleteFileIfExists(oldest.path);
    }
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
