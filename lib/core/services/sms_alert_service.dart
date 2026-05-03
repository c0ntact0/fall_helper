import 'package:flutter/services.dart';

abstract class SmsAlertService {
  Future<void> sendFallAlertSms({
    required String phoneNumber,
    required String message,
  });
}

class SmsAlertServiceImpl implements SmsAlertService {
  static const MethodChannel _channel = MethodChannel('fall_helper/sms_alert');

  @override
  Future<void> sendFallAlertSms({
    required String phoneNumber,
    required String message,
  }) async {
    await _channel.invokeMethod('sendSms', <String, dynamic>{
      'phoneNumber': phoneNumber,
      'message': message,
    });
  }
}
