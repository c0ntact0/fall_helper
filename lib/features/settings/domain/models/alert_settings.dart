class AlertSettings {
  final bool makePhoneCall;
  final bool sendSms;
  final bool sendGps;
  final bool recordAndSendVideo;
  final int circularRecordingMinutes;

  const AlertSettings({
    required this.makePhoneCall,
    required this.sendSms,
    required this.sendGps,
    required this.recordAndSendVideo,
    required this.circularRecordingMinutes,
  });

  AlertSettings copyWith({
    bool? makePhoneCall,
    bool? sendSms,
    bool? sendGps,
    bool? recordAndSendVideo,
    int? circularRecordingMinutes,
  }) {
    return AlertSettings(
      makePhoneCall: makePhoneCall ?? this.makePhoneCall,
      sendSms: sendSms ?? this.sendSms,
      sendGps: sendGps ?? this.sendGps,
      recordAndSendVideo: recordAndSendVideo ?? this.recordAndSendVideo,
      circularRecordingMinutes:
          circularRecordingMinutes ?? this.circularRecordingMinutes,
    );
  }
}
