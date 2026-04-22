import 'dart:io';

import 'package:flutter/services.dart';

class PhoneCallService {
  static const MethodChannel _channel = MethodChannel('fall_helper/phone_call');

  Future<void> callPhoneNumber(String phoneNumber) async {
    final sanitizedNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (sanitizedNumber.isEmpty) {
      throw Exception('Número de telefone inválido.');
    }

    if (!Platform.isAndroid) {
      throw UnsupportedError(
        'A chamada direta só está implementada para Android.',
      );
    }

    await _channel.invokeMethod<void>('callPhoneNumber', <String, String>{
      'phoneNumber': sanitizedNumber,
    });
  }
}
