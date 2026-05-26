import 'package:flutter/foundation.dart';

import '../../../../core/services/video_storage_service.dart';
import '../../domain/models/video_evidence.dart';
import '../../domain/models/video_loop_settings.dart';
import '../../services/circular_video_recorder.dart';

class VideoLoopController extends ChangeNotifier {
  VideoLoopController({
    required CircularVideoRecorder recorder,
    required VideoStorageService storageService,
  }) : _recorder = recorder,
       _storageService = storageService;

  final CircularVideoRecorder _recorder;
  final VideoStorageService _storageService;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  bool _isRunning = false;
  bool get isRunning => _isRunning;

  bool _isPreservingEvidence = false;
  bool get isPreservingEvidence => _isPreservingEvidence;

  String? _lastEvidenceFolder;
  String? get lastEvidenceFolder => _lastEvidenceFolder;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  VideoLoopSettings _settings = const VideoLoopSettings(
    enabled: false,
    bufferSeconds: 30,
    withAudio: false,
    quality: VideoLoopQuality.p480,
    fps: 15,
    segmentSeconds: 5,
  );

  VideoLoopSettings get settings => _settings;

  Future<void> initialize(VideoLoopSettings settings) async {
    _settings = settings;
    _isEnabled = settings.enabled;

    if (!_isEnabled) {
      _isInitialized = false;
      notifyListeners();
      return;
    }

    try {
      await _recorder.initialize(settings);
      _isInitialized = true;
    } catch (e) {
      _errorMessage = 'Falha ao iniciar gravação circular: $e';
      _isInitialized = false;
    }

    notifyListeners();
  }

  Future<void> startIfEnabled() async {
    if (!_isEnabled || _isRunning) return;

    _isRunning = true;
    notifyListeners();

    _recorder.start(_settings).catchError((e) {
      _errorMessage = 'Falha ao arrancar gravação circular: $e';
      _isRunning = false;
      notifyListeners();
    });
  }

  Future<void> stop({bool clearBuffer = false}) async {
    await _recorder.stop(clearBuffer: clearBuffer);
    _isRunning = false;

    if (clearBuffer) {
      _lastEvidenceFolder = null;
    }

    notifyListeners();
  }

  Future<void> disableAndClear() async {
    _isEnabled = false;
    _isRunning = false;
    _isInitialized = false;
    _lastEvidenceFolder = null;

    await _recorder.shutdown(clearBuffer: true);
    notifyListeners();
  }

  Future<VideoEvidence?> captureAlertEvidence({
    required DateTime alertTime,
    int postEventSeconds = 10,
  }) async {
    if (!_isEnabled) return null;

    _isPreservingEvidence = true;
    notifyListeners();

    try {
      final segments = await _recorder.captureAlertSegments(
        postEventSeconds: postEventSeconds,
      );

      if (segments.isEmpty) {
        _errorMessage = 'Sem segmentos de vídeo disponíveis para a evidência.';
        return null;
      }

      final evidence = await _storageService.preserveEvidence(
        segments: segments,
        alertTime: alertTime,
      );

      _lastEvidenceFolder = evidence.folderPath;
      _isRunning = false;
      return evidence;
    } catch (e) {
      _errorMessage = 'Falha ao preservar vídeo do alerta: $e';
      return null;
    } finally {
      _isPreservingEvidence = false;
      notifyListeners();
    }
  }

  Future<void> restartLoopIfEnabled() async {
    if (!_isEnabled) return;
    await startIfEnabled();
  }

  void clearError() {
    _errorMessage = null;
  }

  Future<void> disposeAsync() async {
    await _recorder.dispose();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
