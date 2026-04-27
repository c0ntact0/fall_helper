enum VideoLoopQuality { p480, p720 }

class VideoLoopSettings {
  final bool enabled;
  final int bufferSeconds;
  final bool withAudio;
  final VideoLoopQuality quality;
  final int fps;
  final int segmentSeconds;

  const VideoLoopSettings({
    required this.enabled,
    required this.bufferSeconds,
    required this.withAudio,
    required this.quality,
    required this.fps,
    this.segmentSeconds = 5,
  });

  VideoLoopSettings copyWith({
    bool? enabled,
    int? bufferSeconds,
    bool? withAudio,
    VideoLoopQuality? quality,
    int? fps,
    int? segmentSeconds,
  }) {
    return VideoLoopSettings(
      enabled: enabled ?? this.enabled,
      bufferSeconds: bufferSeconds ?? this.bufferSeconds,
      withAudio: withAudio ?? this.withAudio,
      quality: quality ?? this.quality,
      fps: fps ?? this.fps,
      segmentSeconds: segmentSeconds ?? this.segmentSeconds,
    );
  }
}
