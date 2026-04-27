import 'video_segment.dart';

class VideoEvidence {
  final List<VideoSegment> segments;
  final DateTime alertTime;
  final Duration retainedDuration;
  final String folderPath;

  const VideoEvidence({
    required this.segments,
    required this.alertTime,
    required this.retainedDuration,
    required this.folderPath,
  });
}
