class VideoSegment {
  final String path;
  final DateTime startedAt;
  final DateTime endedAt;
  final Duration duration;

  const VideoSegment({
    required this.path,
    required this.startedAt,
    required this.endedAt,
    required this.duration,
  });
}
